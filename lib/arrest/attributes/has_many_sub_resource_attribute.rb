module Arrest
  class HasManySubResourceAttribute < HasManyAttribute
    alias :super_from_hash :from_hash

    def initialize(ids_field_name,
                   method_name,
                   clazz_name,
                   url_part,
                   foreign_key)
      # the read_only is set to sub_resource to avoid sending post request as ids array
      # directly instead of sending the ids to the sub_resource
      super(ids_field_name, method_name, clazz_name, url_part, foreign_key, true)
    end

    def sub_resource_field_name
      @name
    end

    def from_hash(parent, value)
      return [] if value == nil
      super_from_hash(parent, value)
    end
  end
end
