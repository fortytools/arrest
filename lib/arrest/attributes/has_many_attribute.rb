module Arrest
  class HasManyAttribute < Attribute
    def initialize(name)
      super(name, false, Array)
    end
  end
end