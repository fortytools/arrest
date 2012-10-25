module Arrest

  ##
  # Classloader that specifies the deferred class loading strategy for the user. It is registered as default class loader
  # in the Arrest::Source.
  # The default implementation tries to load the class specified by the given symbol parameter in the following order:
  # 1) from the given module utilising Arrest (in our case SGDB)
  # 2) from Arrest itself (e.g. :Ref)
  # 3) from the Kernel (for all basic types - String, Integer etc)
  class DefaultClassLoader

    def load(sym)
      # Using const_get is effectively a hack - it uses the fact that class names are also constants to allow you to get hold of them.
      # Better use eval if possible

      clazz =
        begin
          eval("#{Source.mod.to_s}::#{sym}") unless Source.mod == Kernel
        rescue NameError
        end


      clazz ||=
        begin
          eval("Arrest::#{sym}")
        rescue NameError
        end

      clazz ||=
        begin
          Kernel.const_get(sym)
        rescue NameError
        end

      raise "Class #{sym} could not be loaded! Tried module if given, with fallback Arrest and Kernel" unless clazz
      clazz
    end
  end

end
