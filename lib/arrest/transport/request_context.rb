module Arrest

  class RequestContext
    attr_accessor :header_decorator

    ##
    # override with actual cache if desired
    def cache
      @cache ||= DummyCache.new
    end

  end

  class IdentityCache
    def initialize()
      @map = {}
    end

    def lookup(id, &blk)
      hit = @map[id]
      unless hit
        hit = @map[id] = yield
      end
      hit.clone
    end

    def update(id, object)
      @map[id] = object
    end
  end

  class DummyCache
    def lookup(id, &blk)
       yield
    end
  end
end

