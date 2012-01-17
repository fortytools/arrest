module Arrest
  class Ref
    include HasAttributes
    
    attribute :id, String
    attribute :type, String
  end
  
  class PolymorphicAttribute < NestedAttribute
    def initialize name, read_only
      super name, read_only, Ref
    end
  end
end