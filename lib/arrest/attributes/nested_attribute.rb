module Arrest
    class NestedAttribute < Attribute
    def initialize name, read_only, clazz
      super name, read_only, clazz
    end

    def from_hash value
      return nil unless value != nil
      @clazz.new value
    end

    def to_hash val
      return nil unless val!= nil
      val.to_hash
    end
  end
end