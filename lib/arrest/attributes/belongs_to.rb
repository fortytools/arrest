module Arrest
  # Manages an id field of an external resource referenced by this resource.
  # Provides accessor to load exteral resource.
  module BelongsTo
    def self.included(base) # :nodoc:
      base.extend BelongsToMethods
    end

    module BelongsToMethods
      def create_field_name(name, params, polymorphic)
        if (params && params[:field_name])
          params[:field_name]
        elsif polymorphic
          "#{name}_ref"
        else
          "#{name}_id"
        end
      end

      def create_and_add_attribute(field_name, polymorphic, read_only, foreign_key, class_name)
        if polymorphic
          add_attribute(PolymorphicAttribute.new(field_name.to_sym, read_only))
        else
          add_attribute(BelongsToAttribute.new(field_name.to_sym, read_only, String, foreign_key, class_name))
        end
      end

      def belongs_to(*args)
        arg = args[0]
        name = arg.to_s.downcase
        class_name = StringUtils.classify(name)
        foreign_key = "#{StringUtils.underscore(ClassUtils.simple_name(self))}_id"
        params = args[1] unless args.length < 2

        if params
          read_only =  params[:read_only] == true
          polymorphic = !!params[:polymorphic]
          class_name = params[:class_name].to_s unless params[:class_name] == nil
          foreign_key = params[:foreign_key].to_s unless params[:foreign_key] == nil
        end

        field_name = create_field_name(name, params, polymorphic)

        create_and_add_attribute(field_name, polymorphic, read_only, foreign_key, class_name)

        send :define_method, name do
          val = self.send(field_name)
          if val == nil || val == ""
            return nil
          end

          begin
            if polymorphic
              clazz = self.class.json_type_to_class(val.type)
              clazz.find(self.context, val.id)
            else
              Arrest::Source.mod.const_get(class_name).find(self.context, val)
            end
          rescue Errors::DocumentNotFoundError => e
            raise Errors::DocumentNotFoundError, "Couldnt find a #{class_name} with id #{val}"
          end

        end
      end
    end
  end
end
