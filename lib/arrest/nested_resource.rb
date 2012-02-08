module Arrest
  # A nested resource has no own url
  # It is an embedded entity in an actual RestResource or
  # an other NestedResource
  class NestedResource
    include HasAttributes
    include BelongsTo

    attr_reader :parent

    def initialize parent, h
      @parent = parent
      init_from_hash h
    end

    def context
      parent.context
    end
  end
end
