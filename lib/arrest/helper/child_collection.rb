module Arrest
  class ChildCollection < BasicObject
    def initialize parentX, clazz_name
      @parent = parentX
      @clazz_name = clazz_name
      @children = nil
    end

    def method_missing(*args, &block)
     if resolved_class.respond_to?(args[0])
       resolved_class.send(args[0], @parent)
     else
       children.send(*args, &block)

     end
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
