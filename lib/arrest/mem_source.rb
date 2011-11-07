module Arrest
  class MemSource

    attr_accessor :data

    @@data = {}

    def data
      @@data
    end

    def initialize
    end

    def wrap content,count
      "{
        \"queryTime\" : \"0.01866644\",
        \"resultCount\" : #{count},
        \"result\" : #{content} }"

    end

    def get sub
      idx = sub.rindex(/\/[0-9]*$/)
      if idx
        ps = [sub[0..(idx-1)], sub[(idx+1)..sub.length]]
      else
        ps = [sub]
      end
      val = traverse @@data,ps
      if val.is_a?(Hash)
        wrap collection_json(val.values), val.length
      elsif val == nil
        wrap "{}", 0
      else
        wrap val.to_hash.to_json, 1
      end
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
      @@data[rest_resource.resource_path()].delete(rest_resource.id.to_s) 
      rest_resource
    end

    def put rest_resource
      raise "To change an object it must have an id" unless rest_resource.respond_to?(:id) && rest_resource.id != nil
      @@data[rest_resource.resource_path()][rest_resource.id.to_s] = rest_resource
      rest_resource
    end

    def post rest_resource
      raise "new object must have setter for id" unless rest_resource.respond_to?(:id=)
      raise "new object must not have id" if rest_resource.respond_to?(:id) && rest_resource.id != nil
      if @@data[rest_resource.resource_path()] != nil
        last_id = @@data[rest_resource.resource_path()].values.map(&:id).sort.last
      else
        last_id = 42
      end
      if last_id.is_a?(Integer)
        next_id = last_id + 1
      else
        next_id = "#{last_id}x"
      end
      rest_resource.id = next_id
      unless @@data[rest_resource.resource_path()] != nil
        @@data[rest_resource.resource_path()] = {}
      end
      @@data[rest_resource.resource_path()][next_id.to_s] = rest_resource
      next_id
    end
  end
end
