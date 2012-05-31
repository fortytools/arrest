module Arrest
  class Attribute
    attr_accessor :name, :read_only, :clazz, :json_name
    def initialize name, read_only, clazz
      @name = name.to_sym
      @read_only = read_only
      @clazz = clazz
      @json_name = Source.json_key_converter.key_to_json(name).to_sym
    end

    def from_hash(parent, value)
      return if value == nil

      if @clazz.respond_to?(:convert)
        return @clazz.convert(value)
      end

      converter = CONVERTER[@clazz]
      if converter == nil
        puts "No converter for: #{@clazz.name}"
        converter = IdentConv
      end
      converter.convert value
    end


    def to_hash value
      return nil unless value != nil

      if @clazz.respond_to?(:mk_json)
        return @clazz.mk_json(value)
      end

      converter = CONVERTER[@clazz]
      if converter == nil
        puts "No converter for: #{@clazz.name}"
        converter = IdentConv
      end
      converter.mk_json value
    end
  end
end
