require 'json'

module Arrest
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
        self.new hash
      end

      def resource_name
        self.name.sub(/.*:/,'').downcase.plural
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
         Arrest::Source.mod.const_get(clazz_name.classify).all_for self
        end
      end

      def parent(*args)
        method_name = args[0].to_s.to_sym
        send :define_method, method_name do
          self.parent
        end
      end

      def add_attribute attribute_name
          if @fields == nil
            @fields = []
          end
          @fields << attribute_name
      end

      def attributes(*args)
        args.each do |arg|
          self.send :attr_accessor,arg
          add_attribute arg
        end
      end

      def belongs_to(*args)
        arg = args[0]
        name = arg.to_s.downcase
        attributes "#{name}_id".to_sym
        send :define_method, name do
          val = self.instance_variable_get("@#{name}_id")
          Arrest::Source.mod.const_get(name.classify).find(val)
        end
      end
    end

    attr_accessor :id

    def initialize  as_i
      as = {}
      as_i.each_pair do |k,v|
        as[k.to_sym] = v
      end
      unless self.class.fields == nil
        self.class.fields.each do |field|
          json_name = field.to_s.classify(false)
          json_name[0] = json_name[0].downcase
          self.instance_variable_set("@#{field.to_s}", as[json_name.to_sym]) 
        end
      end
      self.id = as[:id]
    end

    def to_hash
      result = {}
      unless self.class.fields == nil
        self.class.fields.each do |field|
          json_name = field.to_s.classify(false)
          result[json_name] = self.instance_variable_get("@#{field.to_s}")
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
