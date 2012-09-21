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
      @attribute_values ||= {}
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

        @attribute_values[field.name.to_sym] = converted

        self.send(field.name.to_s + '=', converted) unless converted == nil
      end
      self.reset_dirtiness
    end

    def reset_dirtiness
      self.class.all_fields.each do |field|
        field.dirty = false
      end
    end

    def attributes
      @attribute_values ||= {}
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

    def load_from_stub
      @load_blk.call
      @stubbed = false
    end


    def to_jhash(action)
      to_hash(false, true, action)
    end

    def to_hash(show_all_fields = true, json_names = false, action = nil)
      result = {}

      self.class.all_fields.each do |field|

       if render_field_to_hash?(field, show_all_fields, action)

          if json_names
            json_name = field.json_name
          else
            json_name = field.name
          end
          val = self.send(field.name)
          converted = field.to_hash val

          result[json_name] = converted
        end
      end
      result
    end

    # decides whether attribute field will be rendered to hash
    # either all, or, if an CRUD action given, only those sensitive to this action
    # and if the action is update only those being dirty
    def render_field_to_hash?(field, show_all_fields, action)
      show_all_fields || !action || (field.actions.include?(action) && (action != :update || field.dirty?))
    end

    module HasAttributesClassMethods
      attr_accessor :fields

      def initialize
        @fields = []
      end

      def attribute(name, clazz, attribs = {})
        if !!attribs[:read_only] && !attribs[:actions]
          actions = [:retrieve]
        else
          actions = attribs[:actions]
        end
        add_attribute Attribute.new(name, clazz, actions)
      end

      def attributes(args)
        args.each_pair do |name, clazz|
          self.attribute name, clazz
        end
      end

      def add_attribute(attribute)
        @fields ||= []
        # define setter for attribute value
        send :define_method, "#{attribute.name}=" do |v|
          converted_v = convert(attribute, v)
          Arrest::debug "setter #{self.class.name} #{attribute.name} = #{converted_v}"

          attribute.dirty = true

          self.attribute_values[attribute.name] = converted_v
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
        @all_fields ||=
          self.ancestors.select{|a| a.include?(HasAttributes)}.map(&:fields).flatten.reject{|f| f == nil}
      end

      def nested name, clazz, options = {}
        add_attribute NestedAttribute.new(name, clazz, options[:actions])
      end

      def nested_array name, clazz, options = {}
        add_attribute Arrest::NestedCollection.new(name, clazz, options[:actions])
      end
    end

    def stubbed?
      @stubbed
    end

    private
      # attribute setter checks for proper conversion of v into attribute type
      def convert(attribute, v)
        clazz = attribute.clazz
        # either as it is already the correct (||nested_array) type
        if v == nil || v.is_a?(clazz) || (attribute.is_a?(Arrest::NestedCollection) && v.is_a?(Array))
          converted_v = v
        elsif attribute.is_a?(Arrest::NestedAttribute) && v.is_a?(Hash) # a nested attribute needs a parent and a hash
          converted_v = attribute.from_hash(self, v)
        elsif clazz.respond_to?(:convert) # or its clazz implements a convert method
          converted_v = clazz.convert(v)
        elsif CONVERTER[clazz]            # or a converter has been registered in arrest
          converted_v = CONVERTER[clazz].convert(v)
        else                              # otherwise raise
          raise ArgumentError, "Setting of attribute with type >#{clazz}< with value type >#{v.class}< failed."
        end
        converted_v
      end

  end
end
