module Arrest
  class HasManyAttribute < Attribute
    attr_reader :method_name, :clazz_name, :url_part
    def initialize(ids_field_name, 
                   method_name,
                   clazz_name,
                   url_part)
      super(ids_field_name, false, Array)
      @method_name = method_name.to_sym
      @clazz_name = clazz_name.to_sym
      @url_part = url_part.to_sym
    end
  end
end