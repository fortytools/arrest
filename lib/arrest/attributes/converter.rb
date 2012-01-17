class Boolean
  # to have a boolean type for attributes
end

module Arrest

  class NestedCollection < Attribute
    def initialize name, read_only, clazz
      super name, read_only, clazz
    end

    def from_hash value
      return nil unless value != nil
      raise "Expected an array but got #{value.class.name}" unless value.is_a?(Array)
      value.map do |v|
        @clazz.new v
      end
    end

    def to_hash value
      return nil unless value != nil
      raise "Expected an array but got #{value.class.name}" unless value.is_a?(Array)
      value.map(&:to_hash)
    end

  end

  CONVERTER = {}

  def add_converter key, converter
    CONVERTER[key] = converter
  end

  class Converter
    class << self
      attr_reader :clazz

      def convert value
        if value.is_a?(self.clazz)
          value
        else
          self.parse value
        end
      end

      def mk_json obj
        obj
      end

      def target clazz
        @clazz = clazz
        CONVERTER[clazz] = self
      end
    end
  end
  
  class IdentConv < Converter
    def self.convert value
      value
    end
  end

  class StringConv < IdentConv
    target String
  end

  class BooleanConv < IdentConv
    target Boolean
  end

  class IntegerConv < IdentConv
    target Integer
  end

  class ArrayConv < IdentConv
    target Array
  end


  class TimeConv < Converter
    target Time

    def self.parse value
      Time.parse(value)
    end

    def self.mk_json time
      time.strftime "%FT%T%z"
    end
  end
end
