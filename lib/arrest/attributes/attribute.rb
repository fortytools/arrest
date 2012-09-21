module Arrest

  module Dirty
  end
  Integer.send(:include, Dirty)
  String.send(:include, Dirty)
  Float.send(:include, Dirty)
  Boolean.send(:include, Dirty)


  class Attribute
    attr_accessor :name, :actions, :clazz, :json_name, :dirty

    def initialize(name, clazz, actions = nil)
      @name = name.to_sym
      @actions = actions || [:create, :retrieve, :update, :delete]
      @clazz = clazz
      @dirty_sensitive = @clazz.ancestors.include?(Dirty)
      @dirty = false
      @json_name = Source.json_key_converter.key_to_json(name).to_sym
    end

    def read_only?
      @actions == [:retrieve]
    end

    def mutable?
      @actions.include?(:create) || @actions.include?(:update)
    end

    def dirty?
      if @dirty_sensitive
        @dirty
      else
        true # treat as 'always' dirty
      end
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
