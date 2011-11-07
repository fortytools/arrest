module Arrest

  class Source 
    class << self
      attr_reader :source
      attr_reader :mod

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

    end
  end
  Source.mod = nil
end
