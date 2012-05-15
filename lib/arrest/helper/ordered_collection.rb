module Arrest
  class OrderedCollection #< BasicObject

    def initialize(context,class_or_class_name, base_url, filter = {})
      @filter = filter
      @context = context
      if class_or_class_name.is_a?(String) || class_or_class_name.is_a?(Symbol)
        @clazz_name = (StringUtils.classify(class_name.to_s))
      else
        @clazz = class_or_class_name
      end
      @base_url = base_url
      @collection = nil
      @page = 1
      @page_size = nil
      @per_page = 5
    end

    def method_missing(*args, &block)
       collection.send(*args, &block)
    end

    def limit(count)
      if count != @page_size
        @collection = nil
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
        @collection = nil
      end
      @page = new_page
      self
    end

    def total_count
      collection() # make sure request was made before
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
        @collection = nil
      end
      @page_size = @per_page
      @page = num.to_i
      self
    end

    private

    def collection
      if @collection == nil
        params = {}
        if @page_size
          params[:pageSize] = @page_size
          params[:page] = @page
        end
        params.merge!(@filter) # override with params that got passed in
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

  end
end

