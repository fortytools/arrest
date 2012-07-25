module Arrest
  class IdsCollection

    def initialize(parent, ids_url)
      @collection = nil
      @parent = parent
      @url = ids_url
    end

    def method_missing(*args, &block)
      collection.send(*args, &block)
    end

    def inspect
      collection.inspect
    end

    private

    def collection
      unless @collection

        r = @parent.class.source().get(@parent.context, "#{@url}")
        @collection = @parent.class.body_root(r)

      end
      @collection
    end

  end
end
