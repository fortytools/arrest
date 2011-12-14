module Arrest
  class RootResource < AbstractResource

    class << self

      def resource_path
        "#{self.resource_name}"
      end

      def all filter={}
        body = body_root(source().get_many self.resource_path, filter)
        body ||= []
        body.map do |h|
          self.build h
        end
      end

      def find id
        r = source().get_one "#{self.resource_path}/#{id}"
        body = body_root(r)
        if body == nil || body.empty?
          raise Errors::DocumentNotFoundError.new
        end
        self.build body.merge({:id => id})
      end

      def filter name, &aproc
        if aproc != nil
          send :define_singleton_method, name do |args|
            self.all.select do |instance|
              instance.instance_exec(args, &aproc)
            end
          end
        else
          raise "You must specify a block for a filter"
        end
      end

      def scope name, &block
        super(name)
        if block_given?
          send :define_singleton_method, name do
            self.all.select &block 
          end
        else
          send :define_singleton_method, name do
            body_root(source().get_many self.scoped_path(name)).map do |h|
              self.build(h)
            end
          end
        end

      end

      def scoped_path scope_name
        resource_path + '/' + scope_name.to_s
      end

      def stub stub_id
        n = self.new
        n.initialize_has_attributes({:id => stub_id}) do
          r = n.class.source().get_one "#{self.resource_path}/#{stub_id}"
          body = n.class.body_root(r)
          n.init_from_hash(body, true)
        end
        n
      end
    end

    def resource_path
      "#{self.class.resource_name}"
    end

    def resource_location
      self.class.resource_path + '/' + self.id.to_s 
    end

  end
end

