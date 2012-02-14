require "arrest/source"
require 'active_model'

module Arrest


  class Null
    @@NULL = Null.new()

    def self.singleton
      @@NULL
    end

    def to_json(*a)
      'null'
    end
  end

  module HasAttributes

    attr_accessor :attribute_values

    def initialize_has_attributes(hash, from_json = false, &blk)
      if block_given?
        @stubbed = true
        @load_blk = blk
      else
        @stubbed = false
      end
      raise "hash expected but got #{hash.class}" unless hash.is_a?(Hash)
      init_from_hash(hash, from_json)
    end

    def initialize(hash = {}, from_json = false, &blk)
      raise "hash expected but got #{hash.class}" unless hash.is_a?(Hash)
      if block_given?
        @stubbed = true
        @load_blk = blk
      else
        init_from_hash(hash, from_json)
      end
    end

    # enables the implicit inclusion of these methods as class methods in the including class
    # (AbstractResource)
    def self.included(base) # :nodoc:
      base.extend HasAttributesClassMethods
    end

    def init_from_hash(as_i={}, from_json = false)
      raise "hash expected but got #{as_i.class}" unless as_i.is_a?(Hash)
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
        converted = field.from_hash(self, value)
        self.send(field.name.to_s + '=', converted) unless converted == nil
      end
    end

    def attributes
      self.attribute_values
    end

    def attributes=(attribute_hash = {})
      fields = self.class.all_fields
      field_names = fields.map(&:name)
      attribute_hash.each_pair do |k,v|
        matching_fields = fields.find_all{|f| f.name.to_s == k.to_s}
        field = matching_fields.first
        if field
          converted = field.from_hash(self, v)
          self.send("#{k}=", converted)
        end
      end
    end

    def update_attributes(attribute_hash = {})
      self.attributes= attribute_hash
      self.save
    end

    def reload
      hash = self.class.find(self.context, self.id).to_hash
      self.attributes= hash
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

    module HasAttributesClassMethods
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
        # define setter for attribute value
        if (attribute.is_a?(HasManySubResourceAttribute))
          send :define_method, "#{attribute.name}=" do |v|
            raise ArgumentError, 'Argument is not of Array type' unless v.is_a?(Array)
            Arrest::debug "setter #{self.class.name} #{attribute.name} = #{v}"

            # inform ActiveModel::Dirty about dirtiness of this attribute
            self.send("#{attribute.name}_will_change!") unless v == self.attribute_values[attribute.name]

            self.attribute_values[attribute.name] = v
          end
        else
          send :define_method, "#{attribute.name}=" do |v|
            Arrest::debug "setter #{self.class.name} #{attribute.name} = #{v}"
            self.attribute_values[attribute.name] = v
          end
        end

        # define getter for attribute value
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

      def nested name, clazz, options = {}
        read_only = !!options[:read_only]
        add_attribute NestedAttribute.new(name, read_only, clazz)
      end

      def nested_array name, clazz, options = {}
        read_only = !!options[:read_only]
        add_attribute NestedCollection.new(name, read_only, clazz)
      end
    end

    def stubbed?
      @stubbed
    end
  end
end
