module Arrest
  class RootResource < AbstractResource

    class << self

      def resource_path
        "#{self.resource_name}"
      end

      def all filter={}
        body = body_root(source().get self.resource_path, filter)
        body ||= []
        body.map do |h|
          self.build h
        end
      end

      def find id
        r = source().get "#{self.resource_path}/#{id}"
        body = body_root(r)
        if body == nil || body.empty?
          raise Errors::DocumentNotFoundError.new
        end
        self.build body
      end

      def scope name
        super name
        send :define_singleton_method, name do
          body_root(source().get self.scoped_path(name)).map do |h|
            self.build(h)
          end
        end

      end

      def scoped_path scope_name
        resource_path + '/' + scope_name.to_s
      end
    end

    def resource_path
      "#{self.class.resource_name}"
    end

    def resource_location
      self.class.resource_path + '/' + self.id.to_s 
    end


    def unstub
      return unless @stub
      r = self.class.source().get "#{self.resource_path}/#{id}"
      body = self.class.body_root(r)
      underscored_hash = {}
      body.each_pair do |k, v|
        underscored_hash[StringUtils.underscore k] = v
      end
      init_from_hash underscored_hash
    end

  end
end

