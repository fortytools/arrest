module Arrest
  module Errors

    class DocumentNotFoundError  < StandardError
    end

    class SpecifiedDocumentNotFoundError < DocumentNotFoundError
      attr_reader :id, :class_type

      def initialize(id = nil, class_type = nil)
        @id = id
        @class_type = class_type
      end
    end

    class PermissionDeniedError < StandardError
      def initialize(err_obj)
        super(err_obj)
      end
    end

  end
end
