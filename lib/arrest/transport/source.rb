require "arrest/handler"
module Arrest
  def self.debug s
    if Arrest::Source.debug
      puts s
    end
  end

  class Source
    class << self
      attr_accessor :debug
      attr_reader :source
      attr_reader :mod
      attr_reader :header_decorator
      attr_accessor :json_key_converter
      attr_accessor :skip_validations
      attr_accessor :error_handler
      attr_accessor :call_logger

      def source=(host=nil)
        if [nil, ""].include?(host)
          @source = MemSource.new
          Arrest::logger.info "Setting Arrest host empty in-memory-store"
        else
          @source = HttpSource.new host
          Arrest::logger.info "Setting Arrest host to #{host}"
        end
        @source
      end

      def mod=(mod=nil)
        if mod == nil
          @mod = Kernel
        elsif mod.is_a?(Module)
          @mod = mod
        else
          raise "Expected module but got #{mod.class.name}"
        end
      end

      def header_decorator=(hd=nil)
        Arrest::debug "Setting headerd to #{hd}"
        if hd == nil
          @header_decorator = Handlers::Header_decorator
        elsif hd.respond_to?(:headers)
          @header_decorator = hd
        else
          raise "Header_decorator must be an object that returns an hash for the method headers"
        end
      end
    end
  end
  Source.mod = nil
  Source.header_decorator = Handlers::HeaderDecorator
  Source.debug = false
  Source.json_key_converter = Handlers::IdentityJSONKeyConverter
  Source.error_handler = Handlers::ErrorHandler
  Source.call_logger = Handlers::CallLogger
  Source.skip_validations = false

end
