module Arrest
  class OrderedCollection #< BasicObject

    def initialize(context, class_or_class_name, base_url, query_params = {})
      @collection = nil
      @context = context

      if class_or_class_name.is_a?(String) || class_or_class_name.is_a?(Symbol)
        @clazz_name = (StringUtils.classify(class_or_class_name.to_s))
      else
        @clazz = class_or_class_name
      end
      @base_url = base_url

      @default_page = 1
      @default_page_size = 5

      @page_hash = {}
      @sort_hash = {}
      @query_params = query_params

      define_filters
      define_scopes
    end

    def build(attributes = {})
      resolved_class.new(@context, attributes)
    end


    def method_missing(*args, &block)
      collection.send(*args, &block)
    end

    def inspect
      collection.inspect
    end

    def limit(count)
      page(count)
      self
    end

    def offset(count)
      if @page_hash[:pageSize]
        new_page = count / @page_hash[:pageSize]
      else
        new_page = 1
      end
      page(new_page)
      self
    end

    def total_count
      collection() # make sure request was made before
      @total_count
    end

    # == for kaminari
    # TODO: move to external module

    def limit_value #:nodoc:
      @page_hash[:pageSize] || 0
    end

    def offset_value #:nodoc:
      ((@page_hash[:pageSize] || 0) * (current_page - 1)) || 0
    end

    def current_page
      @page_hash[:page] || @default_page
    end

    def num_pages
      if @page_hash[:pageSize]
        (total_count.to_f / (@page_hash[:pageSize])).ceil
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
      @page_hash[:page] || @default_page
    end

    def per(num)
      @collection = nil unless @page_hash[:pageSize] == num.to_i

      @page_hash[:pageSize] = num.to_i
      @page_hash[:page] ||= @default_page
      self
    end

    def page(num)
      @collection = nil unless @page_hash[:page] == num.to_i

      num ||= 1
      @page_hash[:page] = num.to_i
      @page_hash[:pageSize] ||= @default_page_size
      self
    end

    def order_by(field, order = :asc)
      @collection = nil if @sort_hash[:sort] != field.to_sym || @sort_hash[:order] != order.to_sym

      @sort_hash = {:sort => field.to_sym, :order => order.to_sym}
      self
    end

    private

    def collection

      unless @collection
        params = {}
        params.merge!(@page_hash)
        params.merge!(@sort_hash)

        params.merge!(@query_params) # override with params that got passed in
        url = build_url(@base_url, params)

        response = resolved_class.by_url(@context, url)
        @total_count = response[:result_count]

        @collection = response[:collection]
      end
      @collection
    end


    def build_url(base_url, params_hash)
      return base_url if params_hash.empty?
      query_str = (base_url.include?('?') ? '&' : '?')
      query_str += params_hash.map{|k,v| "#{k}=#{v}"}.join('&')
      base_url + query_str
    end

    def resolved_class
      @clazz ||= Source.mod.const_get(@clazz_name)
    end

    def define_filters
      resolved_class.all_filters.each do |filter|
        self.instance_eval <<-"end_eval"
          def #{filter.name} *args
            real_args = [collection] + args
            #{resolved_class.name}.FILTER_#{filter.name}(real_args)
          end
        end_eval
      end
    end

    def define_scopes
      return unless resolved_class.scopes
      resolved_class.scopes.each do |scope|
        resource_name = scope.options[:resource_name] || scope.name
        self.instance_eval <<-"end_eval"
          def #{scope.name} query_params = {}
            OrderedCollection.new(@context, ClassUtils.simple_name(resolved_class), "#{@base_url}/#{resource_name}", query_params)
          end
        end_eval
      end
    end

  end
end

