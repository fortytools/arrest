module Arrest

  class NestedCollection < Attribute
    def initialize name, read_only, clazz
      super name, read_only, clazz
    end

    def from_hash(parent, value)
      return nil unless value != nil
      raise "Expected an array but got #{value.class.name}" unless value.is_a?(Array)
      value.map do |v|
        @clazz.new(parent.context, v)
      end
    end

    def to_hash value
      return nil unless value != nil
      raise "Expected an array but got #{value.class.name}" unless value.is_a?(Array)
      value.map(&:to_hash)
    end
  end
end
