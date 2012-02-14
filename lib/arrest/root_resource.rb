module Arrest
  class RootResource < AbstractResource

    class << self

      def resource_path
        "#{self.resource_name}"
      end

      def by_url(context, url)
        begin
          body = body_root(source().get_many(context, url))
        rescue Arrest::Errors::DocumentNotFoundError
          Arrest::logger.info "DocumentNotFoundError for #{url} gracefully returning []"
          return []
        end
        body ||= []
        body.map do |h|
          self.build(context, h)
        end
      end

      def first(context, filter={})
        all(context,filter).first
      end

      def end(context, filter={})
        all(context,filter).last
      end

      def all(context, filter={})
        begin
          body = body_root(source().get_many(context, self.resource_path, filter))
        rescue Arrest::Errors::DocumentNotFoundError
          Arrest::logger.info "DocumentNotFoundError for #{self.resource_path} gracefully returning []"
          return []
        end
        body ||= []
        body.map do |h|
          self.build(context, h)
        end
      end

      def load(context)
        r = source().get_one(context, "#{self.resource_path}")
        body = body_root(r)
        if body == nil || body.empty?
          Arrest::logger.info "DocumentNotFoundError for #{self.resource_path}"
          raise Errors::DocumentNotFoundError.new
        end
        self.build(context, body)
      end

      def find(context, id)
        if id == nil || "" == id
          Arrest::logger.info "DocumentNotFoundError: no id given"
          raise Errors::DocumentNotFoundError.new
        end
        r = source().get_one(context, "#{self.resource_path}/#{id}")
        body = body_root(r)
        if body == nil || body.empty?
          Arrest::logger.info "DocumentNotFoundError for #{self.resource_path}/#{id}"
          raise Errors::DocumentNotFoundError.new
        end
        resource = self.build(context, body.merge({:id => id}))
        resource
      end

      def filter name, &aproc
        if aproc != nil
          if @filters == nil
            @filters = []
          end
          @filters << Filter.new(name, &aproc)
          send :define_singleton_method, "FILTER_#{name}" do |args = nil|
            collection = args[0]
            call_args = args.drop(1)
            collection.select do |instance|
              instance.instance_exec(*call_args, &aproc)
            end
          end
          send :define_singleton_method, name do |context, args = nil|
            self.all(context).select do |instance|
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
          send :define_singleton_method, name do |context|
            self.all(context).select(&block)
          end
        else
          send :define_singleton_method, name do |context|
            body_root(source().get_many(context, self.scoped_path(name))).map do |h|
              self.build(context, h)
            end
          end
        end

      end

      def scoped_path scope_name
        resource_path + '/' + scope_name.to_s
      end

      def stub(context, stub_id)
        n = self.new(context)
        n.initialize_has_attributes({:id => stub_id}) do
          r = n.class.source().get_one(@context, "#{self.resource_path}/#{stub_id}")
          body = n.class.body_root(r)
          n.init_from_hash(body, true)
        end
        n
      end


      def delete_all(context)
        source().delete_all(context, self.resource_path)
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

