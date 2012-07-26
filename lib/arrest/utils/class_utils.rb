module Arrest
  class ClassUtils
    class << self
      # Returns the simple class name without any preceding modules or namespaces
      # (removes everything up to the last '::' inclusively from class.name)
      def simple_name(clazz)
        clazz.name.gsub(/.*::/,"")
      end
    end
  end
end