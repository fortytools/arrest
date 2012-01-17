module Arrest
  class Attribute
    attr_accessor :name, :read_only, :clazz, :json_name
    def initialize name, read_only, clazz
      @name = name.to_sym
      @read_only = read_only
      @clazz = clazz
      @json_name = Source.json_key_converter.key_to_json(name).to_sym
    end

    def from_hash value
      return if value == nil
      converter = CONVERTER[@clazz]
      if converter == nil
        puts "No converter for: #{@clazz.name}"
        converter = IdentConv
      end
      converter.convert value
    end

    def to_hash value
      return nil unless value != nil
      converter = CONVERTER[@clazz]
      if converter == nil
        puts "No converter for: #{@clazz.name}"
        converter = IdentConv
      end
      converter.mk_json value
    end
  end  
end