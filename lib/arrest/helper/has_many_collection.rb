module Arrest
  class HasManyCollection #< BasicObject
    def initialize parent, clazz_name
      @parent = parent
      @clazz_name = clazz_name
      @children = nil
      @foreign_key_name = (StringUtils.underscore(@parent.class.name).gsub(/^.*\//, '') + '_id').to_sym
    end

    def build attributes = {}
      extended_attrs = attributes.merge({@foreign_key_name => @parent.id})
      resolved_class.new extended_attrs
    end

    def method_missing(*args, &block)
     if resolved_class.respond_to?(args[0])
       #sub_args = [@parent]
       #sub_args += args.drop(1)
       #puts "#{resolved_class.name} - #{args[0]} : #{args} subargs : #{sub_args} "

       #resolved_class.send(args[0], *sub_args)
       r = []
       children.find_all(&block).each {|x| r << x }
       r
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
        url = @parent.resource_location + '/' + resolved_class.resource_name
        @children = resolved_class.by_url(url)
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

