module Arrest
  class NestedAttribute < Attribute

    def initialize name, class_name, options
      super name, class_name, options
    end

    def from_hash(parent, value)
      return nil unless value != nil
      self.clazz.new(parent, value)
    end

    def to_hash val
      return nil unless val!= nil
      val.to_hash
    end
  end
end
