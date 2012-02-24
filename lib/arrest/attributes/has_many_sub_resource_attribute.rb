module Arrest
  class HasManySubResourceAttribute < HasManyAttribute
    alias :super_from_hash :from_hash

    def initialize(ids_field_name,
                   method_name,
                   clazz_name,
                   url_part,
                   foreign_key,
                   read_only)
      # the read_only for the super constructor is set to true to avoid sending post request as ids array in JSON
      # directly instead of modifying the ids via the sub_resource
      super(ids_field_name, method_name, clazz_name, url_part, foreign_key, true)
      @sub_resource_read_only = read_only
    end

    def sub_resource_field_name
      @name
    end

    # this read only hinders the additional put to the sub resource on saving the encapsulating object
    def sub_resource_read_only?
      @sub_resource_read_only
    end

    def from_hash(parent, value)
      return [] if value == nil
      super_from_hash(parent, value)
    end
  end
end
