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

      def create_and_add_attribute(field_name, polymorphic, actions, foreign_key, class_name)
        if polymorphic
          add_attribute(PolymorphicAttribute.new(field_name.to_sym, actions))
        else
          add_attribute(BelongsToAttribute.new(field_name.to_sym, actions, String, foreign_key, class_name))
        end
      end

      def belongs_to(*args)
        arg = args[0]
        name = arg.to_s.downcase
        class_name = StringUtils.classify(name)
        foreign_key = "#{StringUtils.underscore(ClassUtils.simple_name(self))}_id"
        params = args[1] unless args.length < 2

        actions = [:create, :retrieve, :update, :delete]
        if params
          actions = params[:actions] if params[:actions]
          polymorphic = !!params[:polymorphic]
          class_name = params[:class_name].to_s unless params[:class_name] == nil
          foreign_key = params[:foreign_key].to_s unless params[:foreign_key] == nil
        end

        field_name = create_field_name(name, params, polymorphic)

        create_and_add_attribute(field_name, polymorphic, actions, foreign_key, class_name)

        send :define_method, name do
          val = self.send(field_name)
          if val.blank?
            return nil
          end

          @belongs_tos ||= {}
          @belongs_tos[name] ||=
            begin
              if polymorphic
                clazz = self.class.json_type_to_class(val.type)
                id = val.id
              else
                clazz = Arrest::Source.mod.const_get(class_name)
                id = val
              end
              clazz.find(self.context, id)
            end

        end
      end
    end
  end
end
