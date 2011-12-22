module Arrest
  module Validations
    class MethodValidator
      def initialize method = nil, &blk
        @method = method
      end

      def validate input
        input.send(@method)
      end
    end
  end

  module Validatable
    def self.included(base) # :nodoc:
      base.extend ValidatableMethods
    end

    module ValidatableMethods
      def validates_presence_of attribute
        add_validator Validations::PresenceOf.new attribute
      end

      def validates method_name
        add_validator Validations::MethodValidator.new method_name
      end

      def validates_inclusion_of attribute, hash = {}
        add_validator Validations::InclusionOf.new attribute, hash
      end

      def add_validator v
        if @validations == nil
          @validations = []
        end
        @validations << v
      end

      def validations
        if self.superclass.respond_to? :validations
          super_v = self.superclass.validations
        else 
          super_v = []
        end
        if @validations == nil
          @validations = []
        end

        @validations + super_v
      end
    end

    # --------- instance methods ---------
    def valid?
      validate.empty?
    end


    def validate
      vs = self.class.validations
      return [] if vs == nil
      errors = []
      vs.each do |v|
        errors += v.validate self
      end
      errors
    end
  end
end
