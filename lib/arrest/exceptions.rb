module Arrest
  module Errors
    class DocumentNotFoundError < StandardError

    end

    class PermissionDeniedError < StandardError
      def initialize(err_obj)
        super(err_obj)
      end
    end
  end
end
