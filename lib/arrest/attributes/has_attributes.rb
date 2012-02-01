require "arrest/source"
module Arrest
  module HasAttributes
    attr_accessor :attribute_values

    def initialize_has_attributes(hash, from_json = false, &blk)
      if block_given?
        @stubbed = true
        @load_blk = blk
      else
        @stubbed = false
      end
      init_from_hash(hash, from_json)
    end

    def initialize(hash = {}, from_json = false, &blk)
      if block_given?
        @stubbed = true
        @load_blk = blk
      else
        init_from_hash(hash, from_json)
      end
    end

    def self.included(base) # :nodoc:
      base.extend HasAttributesMethods
    end

    def init_from_hash(as_i={}, from_json = false)
      @attribute_values = {} unless @attribute_values != nil
      as = {}
      as_i.each_pair do |k,v|
        as[k.to_sym] = v
      end
      self.class.all_fields.each do |field|
        if from_json
          key = field.json_name
        else
          key = field.name
        end
        value = as[key]
        converted = field.from_hash(value)
        self.send(field.name.to_s + '=', converted) unless converted == nil
      end
    end

    def load_from_stub
      @load_blk.call
      @stubbed = false
    end


    def to_jhash
      to_hash(false, true)
    end

    def to_hash(show_all_fields = true, json_names = false)
      result = {}
      self.class.all_fields.find_all{|a| show_all_fields || !a.read_only}.each do |field|
        if json_names
          json_name = field.json_name
        else
          json_name = field.name
        end
        val = self.send(field.name)
        converted = field.to_hash val
        if converted != nil
          result[json_name] = converted
        end
      end
      result
    end

    module HasAttributesMethods

      attr_accessor :fields

      def initialize
        @fields = []
      end

      def attribute(name, clazz, attribs = {})
        read_only = !!attribs[:read_only]
        add_attribute Attribute.new(name, read_only, clazz)
      end

      def attributes(args)
        args.each_pair do |name, clazz|
          self.attribute name, clazz
        end
      end

      def add_attribute(attribute)
        @fields ||= []
        if (attribute.is_a?(HasManySubResourceAttribute))
          send :define_method, "#{attribute.name}=" do |v|
            raise ArgumentError, 'Argument is not of Array type' unless v.is_a?(Array)
            Arrest::debug "setter #{self.class.name} #{attribute.name} = #{v}"
            self.attribute_values[attribute.name] = v
          end
        else
          send :define_method, "#{attribute.name}=" do |v|
            Arrest::debug "setter #{self.class.name} #{attribute.name} = #{v}"
            self.attribute_values[attribute.name] = v
          end
        end
        send :define_method, "#{attribute.name}" do
          Arrest::debug "getter #{self.class.name} #{attribute.name}"
          self.load_from_stub if @stubbed
          self.attribute_values[attribute.name]
        end
        @fields << attribute
      end

      def all_fields
        self_fields = self.fields
        self_fields ||= []
        if self.superclass.respond_to?('fields') && self.superclass.all_fields != nil
          res = self_fields + self.superclass.all_fields
        else
          res = self_fields
        end
        res
      end

      def nested name, clazz
        add_attribute NestedAttribute.new(name, false, clazz)
      end

      def nested_array name, clazz
        add_attribute NestedCollection.new(name, false, clazz)
      end
    end

    def stubbed?
      @stubbed
    end
  end
end
