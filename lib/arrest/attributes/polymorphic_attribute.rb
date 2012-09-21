module Arrest
  class Ref
    include HasAttributes

    attribute :id, String
    attribute :type, String

    def self.mk_json(value)
      self.to_hash.to_json
    end

    def self.to_hash
      {:id => value.id, :type => value.type}
    end
  end

  class PolymorphicAttribute < NestedAttribute
    def initialize name, actions
      super name, Ref, actions
    end

    def from_hash(parent, value)
      return nil unless value != nil
      @clazz.new(value)
    end
  end
end
