module Arrest
  class HasManyAttribute < Attribute
    attr_reader :method_name, :clazz_name, :url_part, :foreign_key
    def initialize(ids_field_name,
                   method_name,
                   clazz_name,
                   url_part,
                   foreign_key)
      super(ids_field_name, true, Array)
      @method_name = method_name.to_sym
      @clazz_name = clazz_name.to_sym
      @url_part = url_part.to_sym
      @foreign_key = foreign_key.to_sym
    end
  end
end