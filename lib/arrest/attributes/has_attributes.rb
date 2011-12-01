module Arrest
  module HasAttributes

    def self.included(base) # :nodoc:
      base.extend HasAttributesMethods
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
    end
  end
end
