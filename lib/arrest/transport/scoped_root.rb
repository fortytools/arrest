module Arrest
  class ScopedRoot
    attr_accessor :context

    def initialize(context = Arrest::RequestContext.new())
      @context = context
    end

    def self.register_resource(clazz)
      @classes ||= {}
      @classes[clazz] = true
      class_name = ClassUtils.simple_name(clazz)
      send :define_method, class_name do ||
        clazz.mk_proxy(self)
      end
    end

    def self.registered_classes
      @classes ||= {}
      @classes.keys
    end

    def delete_all
      self.class.registered_classes.each do |clazz|
        begin
          clazz.delete_all(@context)
        rescue
          puts "couldnt delete #{clazz.name}s"
        end
      end
    end

    def get_context
      @context
    end
  end

end
