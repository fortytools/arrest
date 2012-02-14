require 'arrest/string_utils'

module Arrest

  RequestLog = Struct.new(:method, :url, :body, :headers)
  ResponseLog = Struct.new(:status, :body)
  CallLog = Struct.new(:request, :response)

  # The classes in this module supply default behaviour
  # for certain processing steps in the consumption ot the
  # rest api
  module Handlers

    class HeaderDecorator
      # must return a hash from header name to value
      def self.headers
        {}
      end
    end


    # a converter to transform between the name of the field in
    # the json object and the name of the field in ruby code.
    # Default behaviour is the identity, i.e. the very same string in
    # JSON as in RUBY
    class IdentityJSONKeyConverter
      class << self
        def key_from_json name
          name.to_s
        end

        def key_to_json name
          name.to_s
        end
      end
    end

    # a converter to transform between the name of the field in
    # the json object and the name of the field in ruby code.
    # Special behaviour is that for an underscored name in ruby
    # a camel cased version in json expected:
    #     ruby    ->     json
    #   started_at    startedAt
    class KeyConverter
      class << self
        def key_from_json name
          StringUtils.underscore(name.to_s)
        end

        def key_to_json name
          StringUtils.classify(name.to_s,false)
        end
      end
    end

    class ErrorHandler
      # a function to convert the body of an http response
      # to a meaningful error message
      def self.convert body, statuscode
        body
      end
    end

    class CallLogger
      def self.log(requestLog, responseLog)
      end
    end

  end

end

