module Arrest
  class MemSource

    attr_accessor :data
    

    @@all_objects = {} # holds all objects of all types,
                       # each having a unique id

    @@collections = {} # maps urls to collections of ids of objects
    
    @@has_many_relations = {}
    
    @@data = {}

    def objects
      @@all_objects
    end

    def collections
      @@collections
    end

    def data
      @@data
    end

    def initialize
      @@all_objects = {} # holds all objects of all types,

      @@collections = {} # maps urls to collections of ids of objects
      @@random = Random.new(42)

    end


    # only to stub collection for development
    #
    def set_collection clazz, scope, objects
      url = clazz.scoped_path scope
      Arrest::debug "url:#{url}"
      @@data[url] = objects
    end

    def wrap content,count
      "{
        \"queryTime\" : \"0.01866644\",
        \"resultCount\" : #{count},
        \"result\" : #{content} }"

    end

    def hash_to_query filters
      ps = []
      filters.each_pair do |k,v|
        ps << "#{k}=v"
      end
      if ps.empty?
        ''
      else
        '?' + ps.join('&')
      end
    end

    def get_many sub, filters = {}
      Arrest::debug sub + (hash_to_query filters)
      # filters are ignored by mem impl so far

      id_list = @@collections[sub] || []
      objects = id_list.map do |id|
        @@all_objects[id]
      end

      wrap collection_json(objects), id_list.length

    end

    def get_one sub, filters = {}
      Arrest::debug sub + (hash_to_query filters)
      # filters are ignored by mem impl so far
      idx = sub.rindex '/'
      if idx
       id = sub[(idx+1)..sub.length]
      end
      val = @@all_objects[id]
      if val == nil
        raise Errors::DocumentNotFoundError
      end
      wrap val.to_jhash.to_json, 1
    end
    
    def delete_all resource_path
      id_list = Array.new(@@collections[resource_path] || [])
      id_list.each do |base_id|
        @@collections.each_pair do |k,v|
          v.reject!{ |id| id == base_id }
        end
        @@all_objects[base_id].delete
      end
    end
    
    def collection_json values
      single_jsons = values.map do |v|
        v.to_jhash.to_json
      end
      "[#{single_jsons.join(',')}]"
    end

    def traverse hash, keys
      if keys.empty?
        return hash
      end
      key = keys.first
      if hash == nil
        nil
      else
        traverse hash[key.to_s],keys.drop(1)
      end
    end


    def delete(rest_resource)
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      @@all_objects.delete(rest_resource.id)
      @@collections.each_pair do |k,v|
        v.reject!{ |id| id == rest_resource.id }
      end
      remove_edges(@@has_many_relations, rest_resource.id)
      rest_resource
    end

    def remove_edges(matrix_sets, node_id)
      if (matrix_sets[node_id])
        matrix_sets[node_id].each do |to_edges|
          puts "EDGES #{to_edges}"
          to_edges.delete(node_id)
        end
        matrix_sets.delete(node_id)
      end
    end

    def store_edge(matrix_sets, from, to)
      if matrix_sets[from] == nil
        matrix_sets[from] = [].to_set
      end
      matrix_sets[from].add(to)
      matrix_sets
    end

    def identify_and_store_edges(matrix_sets, rest_resource)
      from = rest_resource.id
      
      rest_resource.class.all_fields.find_all{|field| field.is_a?(Arrest::HasManyAttribute)}.each do |attr|
        to = rest_resource.send(attr.name)
        if (to != nil) 
          store_edge(matrix_sets, from, to)
          store_edge(matrix_sets, to, from)
        end
      end
    end

    def put(rest_resource)

      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      old = @@all_objects[rest_resource.id]

      rest_resource.class.all_fields.each do |f|
        old.send("#{f.name}=", rest_resource.send(f.name))
      end

      identify_and_store_edges(@@has_many_relations, rest_resource)

      true
    end

    def post(rest_resource)
      
      Arrest::debug "post -> #{rest_resource.class.name} #{rest_resource.to_hash} #{rest_resource.class.all_fields.map(&:name)}"
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id != nil
      rest_resource.id = next_id
      @@all_objects[rest_resource.id] = rest_resource
      unless @@data[rest_resource.resource_path()] != nil
        @@data[rest_resource.resource_path()] = {}
      end
      Arrest::debug "child path #{rest_resource.resource_path()}"
      @@data[rest_resource.resource_path()][next_id.to_s] = rest_resource.id
      if @@collections[rest_resource.resource_path] == nil
        @@collections[rest_resource.resource_path] = []
      end
      @@collections[rest_resource.resource_path] << rest_resource.id

      identify_and_store_edges(@@has_many_relations, rest_resource)

      true
    end

    def cheat_collection url, ids
        @@collections[url] = ids
    end

    def next_id
      (0...32).map{ ('a'..'z').to_a[@@random.rand(26)] }.join
    end
  end
end
