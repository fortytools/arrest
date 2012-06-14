module Arrest
  class HasManyCollection < OrderedCollection 

    def initialize(parent, context, class_or_class_name, base_url, query_params = {})
      super(context, class_or_class_name, base_url, query_params)
      @parent = parent
      @foreign_key_name = (StringUtils.underscore(@parent.class.name).gsub(/^.*\//, '') + '_id').to_sym
    end

    def build(attributes = {})
      resolved_class.new(@context, {@foreign_key_name => @parent.id}.merge!(attributes))
    end
  end
end

