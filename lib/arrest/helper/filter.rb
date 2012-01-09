module Arrest
  # A filter is a named predicate to limit a collection to a subset with
  # certain features
  class Filter
    attr_accessor :name
    attr_accessor :block

    def initialize name, block = nil
      @name = name
      @block = block
    end
  end
end
