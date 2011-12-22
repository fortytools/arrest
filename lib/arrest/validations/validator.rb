module Arrest
  module Validations
    class ValidationError 
      attr_accessor :attribute, :message

      def initialize attribute, message
        @attribute = attribute
        @message = message
      end

      def translate
        "#{self.attribute} - #{self.message}"
      end
    end

    class Validator
      def initialize attribute
        @attribute = attribute
      end

      def validate input
        return []
      end
      
    end
  end
end
