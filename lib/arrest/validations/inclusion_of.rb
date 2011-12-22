module Arrest
  module Validations
    class InclusionOf < Validator

      def initialize attribute, hash
        super attribute
        @hash = hash
      end

      def validate input
        errors = []
        if !input.respond_to?(@attribute)
          errors << ValidationError.new(@attribute, "not_responding")
        else
          val = input.send(@attribute)
          unless @hash[:in] != nil && @hash[:in].include?(val) 
            errors << ValidationError.new(@attribute,"not_included")
          end
        end
        return errors
      end
    end
  end
end

