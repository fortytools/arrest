module Arrest

  module Dirty
  end
  Integer.send(:include, Dirty)
  String.send(:include, Dirty)
  Float.send(:include, Dirty)
  Boolean.send(:include, Dirty)


  class Attribute
    attr_accessor :name, :actions, :json_name, :dirty

    def initialize(name, class_name, actions = nil)
      @name = name.to_sym
      @actions = actions || [:create, :retrieve, :update, :delete]
      @class_name = class_name.to_sym
      @dirty = false
      @json_name = Source.json_key_converter.key_to_json(name).to_sym
    end

    def clazz
      @clazz ||= Arrest::Source.class_loader.load(@class_name)
    end

    def clazz=(c)
      @clazz = c
    end

    def dirty_sensitive?
      @dirty_sensitive ||= clazz.ancestors.include?(Dirty)
    end

    def read_only?
      @actions == [:retrieve]
    end

    def mutable?
      @actions.include?(:create) || @actions.include?(:update)
    end

    def dirty?
      if dirty_sensitive?
        @dirty
      else
        true # treat as 'always' dirty
      end
    end

    def from_hash(parent, value)
      return if value == nil

      if self.clazz.respond_to?(:convert)
        return self.clazz.convert(value)
      end

      converter = CONVERTER[self.clazz]
      if converter == nil
        puts "No converter for: #{self.clazz.name}"
        converter = IdentConv
      end
      converter.convert value
    end


    def to_hash value
      return nil unless value != nil

      if self.clazz.respond_to?(:mk_json)
        return self.clazz.mk_json(value)
      end

      converter = CONVERTER[self.clazz]
      if converter == nil
        puts "No converter for: #{@self.clazz.name}"
        converter = IdentConv
      end
      converter.mk_json value
    end
  end
end
