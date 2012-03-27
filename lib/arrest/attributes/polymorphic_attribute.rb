module Arrest
  class Ref
    include HasAttributes

    attribute :ref_id, String
    attribute :ref_type, String
  end

  class PolymorphicAttribute < NestedAttribute
    def initialize name, read_only
      super name, read_only, Ref
    end

    def from_hash(parent, value)
      return nil unless value != nil
      @clazz.new(value)
    end
  end
end
