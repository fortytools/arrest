module Arrest
  # A nested resource has no own url
  # It is an embedded entity in an actual RestResource or
  # an other NestedResource
  class NestedResource
    include HasAttributes
    include BelongsTo

    attr_reader :context

    def initialize context, h
      @context = context
      init_from_hash h
    end

  end
end
