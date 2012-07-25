module Arrest
  module HasView
    include Arrest::HasAttributes

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_view(*args)

        method_name, options = args
        if options
          clazz = options[:class_name]
        end
        clazz ||= StringUtils.classify(method_name.to_s)

        send :define_method, method_name do
          @views ||= {}
          @views[method_name] ||= begin

            r = self.class.source().get(self.context, "#{self.resource_path}/#{id}/#{method_name}")
            r = self.class.body_root(r)

            Arrest::Source.mod.const_get(clazz).new(self.context, r)
          end
        end
      end
    end
  end
end
