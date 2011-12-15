module Arrest
  class ChildCollection #< BasicObject
    def initialize parent, clazz_name
      @parent = parent
      @clazz_name = clazz_name
      @children = nil
    end

    def build attributes = {}
      resolved_class.new @parent, attributes
    end

    def method_missing(*args, &block)
     if resolved_class.respond_to?(args[0])
       sub_args = [@parent]
       sub_args += args.drop(1)
       resolved_class.send(args[0], *sub_args)
     else
       children.send(*args, &block)
     end
    end

    def inspect
      children.inspect
    end

    private


    def children
      if @children == nil
        @children = resolved_class.all_for @parent
      end
      @children
    end

    def resolved_class
      if @clazz == nil
        @clazz = Source.mod.const_get(@clazz_name)
      end
      @clazz
    end

  end
end
