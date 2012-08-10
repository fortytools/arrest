module Arrest
  # A resource that does not maintain a collection of object
  # but a single object.
  class SingleResource < RootResource
    class << self
      def load(context)
        r = source().get(context, "#{self.resource_path}")
        body = body_root(r)
        if body == nil || body.empty?
          Arrest::logger.info "SpecifiedDocumentNotFoundError for #{self.resource_path}"
          raise Errors::SpecifiedDocumentNotFoundError.new(nil, self.class)
        end
        self.build(context, body)
      end

      def find(context, id)
        raise "A find is not possible for a SingleResource"
      end
    end

    # the single resource does not use an id to identify the object
    # since it's already identified by the reource path
    def resource_location
      self.class.resource_path
    end
  end
end
