module Arrest
  # Manages an id field of an external resource referenced by this resource.
  # Provides accessor to load exteral resource.
  module BelongsTo
    def self.included(base) # :nodoc:
      base.extend BelongsToMethods
    end

    module BelongsToMethods
      def belongs_to(*args)
        arg = args[0]
        name = arg.to_s.downcase
        class_name = StringUtils.classify name
        params = args[1] unless args.length < 2
        field_name = "#{name}_id"
        if params
          read_only =  params[:read_only] == true
          field_name = params[:field_name] unless params[:field_name] == nil
          polymorphic = params[:polymorphic] unless params[:polymorphic] == nil
          class_name = params[:class_name].to_s unless params[:class_name] == nil
        end
        
        if polymorphic
          add_attribute(PolymorphicAttribute.new(field_name.to_sym, read_only))
        else
          add_attribute(Attribute.new(field_name.to_sym, read_only, String))
        end
        
        send :define_method, name do
          val = self.send(field_name)
          if val == nil || val == ""
            return nil
          end 
          
          begin
            if polymorphic
              Arrest::Source.mod.const_get(polymorphic[val.type.to_sym]).find(val.id)
            else
              Arrest::Source.mod.const_get(class_name).find(val)
            end
          rescue Errors::DocumentNotFoundError => e
            raise Errors::DocumentNotFoundError, "Couldnt find a #{class_name} with id #{val}"
          end
          
        end
      end
    end
  end
end
