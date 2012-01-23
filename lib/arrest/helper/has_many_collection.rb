module Arrest
  class HasManyCollection #< BasicObject
    def initialize parent, has_many_attribute
      @parent = parent
      @clazz_name = (StringUtils.classify(has_many_attribute.clazz_name.to_s))
      @url_part = has_many_attribute.url_part
      @children = nil
      @foreign_key_name = (StringUtils.underscore(@parent.class.name).gsub(/^.*\//, '') + '_id').to_sym
      define_filters
    end

    def build attributes = {}
      extended_attrs = attributes.merge({@foreign_key_name => @parent.id})
      resolved_class.new extended_attrs
    end

    def method_missing(*args, &block)
       children.send(*args, &block)
    end

    def inspect
      children.inspect
    end

    private

    def children
      if @children == nil
        url = @parent.resource_location + '/' + @url_part.to_s
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


    def define_filters
      resolved_class.all_filters.each do |filter|
        self.instance_eval <<-"end_eval"
          def #{filter.name} *args
            real_args = [children] + args
            #{resolved_class.name}.FILTER_#{filter.name}(real_args)
          end
        end_eval
      end
    end

  end
end

