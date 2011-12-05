module Arrest
  module HasAttributes

    def self.included(base) # :nodoc:
      base.extend HasAttributesMethods
    end

    def unstub

    end

    def init_from_hash as_i={}
      as = {}
      as_i.each_pair do |k,v|
        as[k.to_sym] = v
      end
      unless self.class.all_fields == nil
        self.class.all_fields.each do |field|
          value = as[field.name.to_sym]
          converted = field.convert(value)
          self.send("#{field.name.to_s}=", converted) 
        end
      end
    end

    def to_hash
      result = {}
      unless self.class.all_fields == nil
        self.class.all_fields.find_all{|a| !a.read_only}.each do |field|
          json_name = StringUtils.classify(field.name.to_s,false)
           val = self.instance_variable_get("@#{field.name.to_s}")
           if val != nil && val.is_a?(NestedResource)
             val = val.to_hash
           end
           result[json_name] = val
        end
      end
      result
    end

    module HasAttributesMethods
      attr_accessor :fields

      
      def attribute name, clazz
          add_attribute Attribute.new(name, false, clazz)

          send :define_method, "#{name}=" do |v|
            self.unstub
            self.instance_variable_set("@#{name}", v)
          end
          send :define_method, "#{name}" do
            self.unstub
            self.instance_variable_get("@#{name}")
          end
      end

      def attributes(args)
        args.each_pair do |name, clazz|
          self.attribute name, clazz
        end
      end

      def add_attribute attribute
          if @fields == nil
            @fields = []
          end
          @fields << attribute
      end

      def all_fields
        self_fields = self.fields
        self_fields ||= []
        if self.superclass.respond_to?('fields') && self.superclass.fields != nil
          self_fields + self.superclass.fields
        else
          self_fields
        end
      end

      def nested name, clazz
          add_attribute NestedAttribute.new(name, false, clazz)

          send :define_method, "#{name}=" do |v|
            self.unstub
            self.instance_variable_set("@#{name}", v)
          end
          send :define_method, "#{name}" do
            self.unstub
            self.instance_variable_get("@#{name}")
          end
        
      end

      def nested_array name, clazz
          add_attribute NestedCollection.new(name, false, clazz)

          send :define_method, "#{name}=" do |v|
            self.unstub
            self.instance_variable_set("@#{name}", v)
          end
          send :define_method, "#{name}" do
            self.unstub
            self.instance_variable_get("@#{name}")
          end
        
      end

    end


  end
end
