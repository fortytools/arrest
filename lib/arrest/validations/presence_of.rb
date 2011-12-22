module Arrest
  module Validations
    class PresenceOf < Validator
      def validate input
        errors = []
        if !input.respond_to?(@attribute)
          errors << ValidationError.new(@attribute, "not_responding")
        else
          val = input.send(@attribute)
          if val == nil || val == ''
            errors << ValidationError.new(@attribute,"not_present")
          end
        end
        return errors
      end
    end
  end
end
