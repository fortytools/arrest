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
          field_name = params[:field_name] unless params[:field_name] == nil
          class_name = params[:class_name].to_s unless params[:class_name] == nil
          read_only =  params[:read_only] == true
        end
        add_attribute(Attribute.new(field_name.to_sym, read_only, String))
        send :define_method, name do
          val = self.send(field_name)
          begin
            Arrest::Source.mod.const_get(class_name).find(val)
          rescue Errors::DocumentNotFoundError => e
            raise Errors::DocumentNotFoundError, "Couldnt find a #{class_name} with id #{val}"
          end
        end
      end
    end
  end
end
