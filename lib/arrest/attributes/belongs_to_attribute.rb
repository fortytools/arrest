module Arrest
  class BelongsToAttribute < Attribute
    attr_accessor :foreign_key

    def initialize(name, actions, field_class_name, foreign_key, target_class_name)
      super(name, field_class_name, actions)
      @foreign_key = foreign_key
      @target_class_name = target_class_name
    end

    def target_class
      @target_class ||= Arrest::Source.class_loader.load(@target_class_name)
    end
  end
end
