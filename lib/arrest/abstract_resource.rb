require 'json'
require 'arrest/string_utils'

module Arrest

  Attribute = Struct.new(:name, :read_only)

  class AbstractResource
    class << self

      attr_accessor :fields

      def source
        Arrest::Source::source
      end

      def body_root response
        all = JSON.parse response
        all["result"]
      end

      def build hash
        underscored_hash = {}
        hash.each_pair do |k, v|
          underscored_hash[StringUtils.underscore k] = v
        end
        self.new underscored_hash
      end

      def resource_name
       StringUtils.plural self.name.sub(/.*:/,'').downcase
      end

      def has_many(*args)
        method_name, options = args
        method_name = method_name.to_sym

        clazz_name = method_name.to_s
        if options
          clazz = options[:class_name]
          if clazz
            clazz_name = clazz.to_s
          end
        end
        send :define_method, method_name do
         Arrest::Source.mod.const_get(StringUtils.classify clazz_name).all_for self
        end
      end

      def parent(*args)
        method_name = args[0].to_s.to_sym
        send :define_method, method_name do
          self.parent
        end
      end

      def add_attribute attribute
          if @fields == nil
            @fields = []
          end
          @fields << attribute
      end

      def all_fields
        if self.superclass.respond_to?('fields') && self.superclass.fields != nil
          self.fields + self.superclass.fields
        else
          self.fields
        end

      end

      def read_only_attributes(*args)
        args.each do |arg|
          self.send :attr_accessor,arg
          add_attribute Attribute.new(arg, true)
        end
      end

      def attributes(*args)
        args.each do |arg|
          self.send :attr_accessor,arg
          add_attribute Attribute.new(arg, false)
        end
      end

      def belongs_to(*args)
        arg = args[0]
        name = arg.to_s.downcase
        attributes "#{name}_id".to_sym
        send :define_method, name do
          val = self.instance_variable_get("@#{name}_id")
          Arrest::Source.mod.const_get(StringUtils.classify name).find(val)
        end
      end
    end

    attr_accessor :id

    def initialize  as_i
      as = {}
      as_i.each_pair do |k,v|
        as[k.to_sym] = v
      end
      unless self.class.all_fields == nil
        self.class.all_fields.each do |field|
          self.send("#{field.name.to_s}=", as[field.name.to_sym]) 
        end
      end
      self.id = as[:id]
    end

    def to_hash
      result = {}
      unless self.class.all_fields == nil
        self.class.all_fields.find_all{|a| !a.read_only}.each do |field|
          json_name = StringUtils.classify(field.name.to_s,false)
          result[json_name] = self.instance_variable_get("@#{field.name.to_s}")
        end
      end
      result[:id] = self.id
      result

    end

    def save
      if self.respond_to?(:id) && self.id != nil
        AbstractResource::source().put self
      else
        AbstractResource::source().post self
      end
    end

    def delete
      AbstractResource::source().delete self
    end

  end
end
