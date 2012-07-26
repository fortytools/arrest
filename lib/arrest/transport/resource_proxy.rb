module Arrest
  ##
  # Forwards context as first parameter to every method call
  # of the proxied class
  class ResourceProxy
    def initialize(resource, context_provider)
      @resource = resource
      @context_provider = context_provider
    end

    def method_missing(*args, &block)
      params = [@context_provider.get_context]
      params += args.drop(1)
      @resource.send(args.first, *params)
    end

    def load(*args)
      ext = [@context_provider.get_context] + args
      @resource.load(*ext)
    end

  end

end
