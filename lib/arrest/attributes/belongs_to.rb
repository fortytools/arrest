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
        attributes({"#{name}_id".to_sym => String})
        send :define_method, name do
          val = self.instance_variable_get("@#{name}_id")
          Arrest::Source.mod.const_get(StringUtils.classify name).find(val)
        end
      end
    end
  end
end
