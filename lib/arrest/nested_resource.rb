module Arrest
  # A nested resource has no own url
  # It is an embedded entity in an actual RestResource or
  # an other NestedResource
  class NestedResource
    include HasAttributes
    include BelongsTo

    def initialize h
      init_from_hash h
    end
  end
end
