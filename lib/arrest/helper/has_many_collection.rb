module Arrest
  class HasManyCollection #< BasicObject

    def initialize(abstract_resource, has_many_attribute)
      @parent = abstract_resource
      @clazz_name = (StringUtils.classify(has_many_attribute.clazz_name.to_s))
      @url_part = has_many_attribute.url_part
      @children = nil
      @foreign_key_name = (StringUtils.underscore(@parent.class.name).gsub(/^.*\//, '') + '_id').to_sym
      define_filters
      @attribute = has_many_attribute
      @page = 1
      @page_size = nil
      @per_page = 5
    end

    def build attributes = {}
      extended_attrs = attributes.merge({@foreign_key_name => @parent.id})
      resolved_class.new(@parent.context, extended_attrs)
    end

    def method_missing(*args, &block)
       children.send(*args, &block)
    end

    def inspect
      children.inspect
    end

    def limit(count)
      if count != @page_size
        @children = nil
      end
      @page_size = count
      self
    end

    def offset(count)
      if @page_size
        new_page = count / @page_size
      else
        new_page = 1
      end
      if new_page != @page
        @children = nil
      end
      @page = new_page
      self
    end

    def total_count
      children() # make sure request was made before
      @total_count
    end

    # == for kaminari
    # TODO: move to external module

    def limit_value #:nodoc:
      @page_size || 0
    end

    def offset_value #:nodoc:
      ((@page_size || 0) * (@page - 1)) || 0
    end

    def current_page
      @page
    end

    def num_pages
      if @page_size
        (total_count.to_f / @page_size).ceil
      else
        1
      end
    end

    def first_page?
      current_page == 1
    end

    def last_page?
      current_page >= num_pages
    end

    def current_page_count #:nodoc:
      @page
    end

    def per(num)
      @per_page = num.to_i
      self
    end

    def page(num)
      num ||= 1
      if @page_size != @per_page || @page != num
        @children = nil
      end
      @page_size = @per_page
      @page = num.to_i
      self
    end

    private

    def children
      if @children == nil
        if @page_size
          query_params = "?pageSize=#{@page_size}&page=#{@page}"
        else
          query_params = ''
        end
        url = @parent.resource_location + '/' + @url_part.to_s + query_params
        response = resolved_class.by_url(@parent.context, url)
        @total_count = response[:result_count]
        @children = response[:collection]
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

