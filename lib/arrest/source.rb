module Arrest

  class Source 
    class << self
      attr_reader :source
      attr_reader :mod
      attr_reader :header_decorator

      def source=(host=nil)
        if host == nil || host.blank?
          @source = MemSource.new
        else
          @source = HttpSource.new host 
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
        puts "Setting headerd to #{hd}"
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

    end
  end
  Source.mod = nil
  Source.header_decorator = Source
end
