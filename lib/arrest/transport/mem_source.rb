module Arrest

  Edge = Struct.new(:foreign_key, :name, :id, :tail)

  class MemSource

    attr_accessor :data


    @@all_objects = {} # holds all objects of all types,
                       # each having a unique id

    @@collections = {} # maps urls to collections of ids of objects

    # For every has_many relation
    @@edge_matrix = {} # matrix of edges based on node ids for has_many and belongs_to relations

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

    def edge_matrix
      @@edge_matrix
    end

    def edge_count
      @@edge_matrix.values.inject(0){|sum, edges| sum + edges.length }
    end

    def node_count
      @@edge_matrix.length
    end

    def initialize
      @@all_objects = {} # holds all objects of all types,

      @@collections = {} # maps urls to collections of ids of objects
      @@random = Random.new(42)

      @@edge_matrix = {}
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

    def parse_for_has_many_relations(resource_path)
      matcher = /^.+\/([^\/]+)\/([^\/]+)$/.match(resource_path)
      return [] unless matcher
      object_id = matcher[1]
      relation = matcher[2]

      if (object_id && relation && @@edge_matrix[object_id])
        result = []
        @@edge_matrix[object_id].each do |edge|
          if (edge.name.to_s == relation)
            result << edge.id
          end
        end
        return result
      end
      []
    end

    def get_many_other_ids(context,path)
      matcher = /^.+\/([^\/]+)\/([^\/]+)_ids$/.match(path)
      return [] unless matcher
      object_id = matcher[1]
      relation = matcher[2] + 's'
      if (object_id && relation && @@edge_matrix[object_id])
        id_list = []
        @@edge_matrix[object_id].each do |edge|
          if (edge.name.to_s == relation)
            id_list << edge.id
          end
        end
      end

      wrap id_list, id_list.length
    end

    def get(context,sub, filters = {})
      Arrest::debug sub + (hash_to_query filters)
      # filters are ignored by mem impl so far

      id_list = parse_for_has_many_relations(sub)
      if id_list.empty?
        id_list = @@collections[sub] || []
      end

      objects = id_list.map do |id|
        @@all_objects[id]
      end

      wrap collection_json(objects), id_list.length
    end

    def get(context, sub, filters = {})
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

    def delete_all(context, resource_path)
      id_list = Array.new(@@collections[resource_path] || [])
      id_list.each do |base_id|
        @@collections.each_pair do |k,v|
          v.reject!{ |id| id == base_id }
        end
        @@all_objects[base_id].delete
        remove_edges(@@edge_matrix, base_id)
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


    def delete(context, rest_resource)
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      @@all_objects.delete(rest_resource.id)
      @@collections.each_pair do |k,v|
        v.reject!{ |id| id == rest_resource.id }
      end
      remove_edges(@@edge_matrix, rest_resource.id)
      rest_resource
    end

    def remove_outgoing_edges(edge_matrix, id)
      if (edge_matrix[id])
        out_edges = edge_matrix[id].find_all{|edge| edge.tail}
        in_edges_to_delete = out_edges.map do |out_edge|
          foreign_edges = edge_matrix[out_edge.id] # the edge set of the foreign node that this node points to
          has_many_back_edges = foreign_edges.find_all do |for_edge|
            for_edge.id == id && for_edge.foreign_key == out_edge.foreign_key
          end
          [has_many_back_edges.first, out_edge.id] # first element may be nil
        end

        in_edges_to_delete.each do |tupel|
          if tupel[0]
            edge_matrix[tupel[1]].delete_if{|e| e.id == tupel[0].id && e.foreign_key == tupel[0].foreign_key}
          end
        end
        edge_matrix[id] = Set.new()
      end
    end

    def remove_edges(edge_matrix, node_id)
      if (edge_matrix[node_id])
        edge_matrix[node_id].each do |edge|
          to_nodes = edge_matrix[edge.id]
          to_nodes.delete_if{|e| e.id == node_id}
        end
        edge_matrix.delete(node_id)
      end
    end

    def identify_and_store_edges(edge_matrix, rest_resource)
      from_id = rest_resource.id

      rest_resource.class.all_fields.each do |attr|
        if attr.is_a?(Arrest::HasManyAttribute)
          to_ids = rest_resource.send(attr.name) # -> foo_ids
          url_part = attr.url_part
          foreign_key = attr.foreign_key
          edge_matrix[from_id] ||= Set.new()
          if to_ids
            to_ids.each do |to_id|
              edge_matrix[from_id].add(Edge.new(foreign_key, url_part, to_id, true))
              edge_matrix[to_id] ||= Set.new()
              edge_matrix[to_id].add(Edge.new(foreign_key, url_part, from_id, false))
            end
          end
        elsif attr.is_a?(Arrest::BelongsToAttribute)
          to_id = rest_resource.send(attr.name)
          if to_id
            foreign_key = attr.foreign_key
            has_many_clazz = attr.target_class()
            hm_candidates = has_many_clazz.all_fields.find_all do |field|
              field.is_a?(Arrest::HasManyAttribute) && field.foreign_key.to_s == foreign_key
            end
            return if hm_candidates.empty?
            has_many_node = hm_candidates.first
            url_part = has_many_node.url_part

            edge_matrix[from_id] ||= Set.new()
            edge_matrix[from_id].add(Edge.new(foreign_key, url_part, to_id, true))
            edge_matrix[to_id] ||= Set.new()
            edge_matrix[to_id].add(Edge.new(foreign_key, url_part, from_id, false))
          end
        end
      end
    end

    def put(context, rest_resource)
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      old = @@all_objects[rest_resource.id]

      remove_outgoing_edges(@@edge_matrix, old.id)

      rest_resource.class.all_fields.each do |f|
        old.send("#{f.name}=", rest_resource.send(f.name))
      end

      true
    end



    def post(context, rest_resource)

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

      true
    end

    def cheat_collection(url, ids)
        @@collections[url] = ids
    end

    def next_id
      (0...32).map{ ('a'..'z').to_a[@@random.rand(26)] }.join
    end
  end
end
