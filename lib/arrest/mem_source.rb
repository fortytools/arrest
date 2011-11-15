module Arrest
  class MemSource

    attr_accessor :data
    

    @@all_objects = {} # holds all objects of all types,
                       # each having a unique id

    @@collections = {} # maps urls to collections of ids of objects

    
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
    end

    def debug s
      if Arrest::Source.debug
        puts s
      end
    end

    # only to stub collection for development
    #
    def set_collection clazz, scope, objects
      url = clazz.scoped_path scope
      self.class.debug "url:#{url}"
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
      debug sub + (hash_to_query filters)
      # filters are ignored by mem impl so far

      id_list = @@collections[sub] || []
      objects = id_list.map do |id|
        @@all_objects[id]
      end

      wrap collection_json(objects), id_list.length

    end

    def get_one sub, filters = {}
      debug sub + (hash_to_query filters)
      # filters are ignored by mem impl so far
      idx = sub.rindex '/'
      if idx
       id = sub[(idx+1)..sub.length]
      end
      val = @@all_objects[id]
      wrap val.to_hash.to_json, 1
    end
    
    def collection_json values
      single_jsons = values.map do |v|
        v.to_hash.to_json
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


    def delete rest_resource
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      @@all_objects.delete(rest_resource.id)
      @@collections.each_pair do |k,v|
        v.reject!{ |id| id == rest_resource.id }
      end
      rest_resource
    end

    def put rest_resource
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      old = @@all_objects[rest_resource.id]

      rest_resource.class.all_fields.each do |f|
        old.send("#{f.name}=", rest_resource.send(f.name))
      end
      true
    end

    def post rest_resource
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id != nil
      rest_resource.id = next_id
      @@all_objects[rest_resource.id] = rest_resource
      unless @@data[rest_resource.resource_path()] != nil
        @@data[rest_resource.resource_path()] = {}
      end
      debug "child path #{rest_resource.resource_path()}"
      @@data[rest_resource.resource_path()][next_id.to_s] = rest_resource.id
      if @@collections[rest_resource.resource_path] == nil
        @@collections[rest_resource.resource_path] = []
      end
      @@collections[rest_resource.resource_path] << rest_resource.id
      true
    end

    def next_id
      (0...32).map{ ('a'..'z').to_a[rand(26)] }.join
    end
  end
end
