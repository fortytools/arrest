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
          @header_decorator = self
        elsif hd.respond_to?(:headers)
          @header_decorator = hd
        else
          raise "Header_decorator must be an object that returns an hash for the method headers"
        end
      end

      def headers
        {}
      end

      def key_from_json name
        StringUtils.underscore(name.to_s)
      end

      def key_to_json name
        StringUtils.classify(name.to_s,false)
      end

    end
  end
  Source.mod = nil
  Source.header_decorator = Source
  Source.debug = false
  Source.json_key_converter = Source
  Source.skip_validations = false

end
