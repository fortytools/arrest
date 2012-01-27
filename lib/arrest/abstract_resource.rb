require 'json'
require 'arrest/string_utils'
require 'time'
require 'active_model'

Scope = Struct.new(:name, :block)

module Arrest
  class AbstractResource
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include HasAttributes
    attribute :id, String

    class << self
      attr_reader :scopes

      def source
        Arrest::Source::source
      end

      def body_root response
        if response == nil
          raise Errors::DocumentNotFoundError
        end
        all = JSON.parse response
        body = all["result"]
        if body == nil
          raise Errors::DocumentNotFoundError
        end
        body
      end

      def build hash
        self.new hash, true
      end

      def custom_resource_name new_name
        @custom_resource_name = new_name
      end

      def resource_name
       if @custom_resource_name
         @custom_resource_name
       else
         StringUtils.plural self.name.sub(/.*:/,'').downcase
       end
      end

      def has_many(*args)
        method_name, options = args
        ids_field_name = (StringUtils.singular(method_name.to_s) + '_ids').to_sym
        method_name = method_name.to_sym
        clazz_name = StringUtils.singular(method_name.to_s)
        foreign_key = clazz_name + "_id"
        sub_resource = false
        if options
          clazz_name = options[:class_name].to_s unless options[:class_name] == nil
          foreign_key = "#{StringUtils.underscore(clazz_name)}_id"
          foreign_key = options[:foreign_key].to_s unless options[:foreign_key] == nil
          sub_resource = !!options[:sub_resource]
        end

        url_part = method_name.to_s

        hm_attr = create_has_many_attribute(sub_resource,
                                            ids_field_name,
                                            method_name,
                                            clazz_name,
                                            url_part,
                                            foreign_key)
        add_attribute(hm_attr)

        send :define_method, method_name do
          if @has_many_collections == nil
            @has_many_collections = {}
          end
          if @has_many_collections[method_name] == nil
            @has_many_collections[method_name] = HasManyCollection.new(self, hm_attr)
          end

          @has_many_collections[method_name]
        end
      end

      def create_has_many_attribute(sub_resource, ids_field_name, method_name,
                                    clazz_name, url_part, foreign_key)
        if sub_resource
          HasManySubResourceAttribute.new(ids_field_name,
                                          method_name,
                                          clazz_name,
                                          url_part,
                                          foreign_key)
        else
          HasManyAttribute.new(ids_field_name,
                               method_name,
                               clazz_name,
                               url_part,
                               foreign_key)
        end
      end

      def children(*args)
        method_name, options = args
        method_name = method_name.to_sym

        clazz_name = method_name.to_s
        if options
          clazz = options[:class_name]
          if clazz
            clazz_name = clazz.to_s
          end
        end
        send :define_method, method_name do
          if @child_collections == nil
            @child_collections = {}
          end
          if @child_collections[method_name] == nil
            @child_collections[method_name]  = ChildCollection.new(self, (StringUtils.classify (StringUtils.singular clazz_name)))
          end

          @child_collections[method_name]
        end
      end

      def parent(*args)
        method_name = args[0].to_s.to_sym
        class_eval "def #{method_name}; self.parent; end"
      end


      def scope name, &block
        if @scopes == nil
          @scopes = []
        end
        @scopes << Scope.new(name, &block)
      end


      def read_only_attributes(args)
        args.each_pair do |name, clazz|
          self.send :attr_accessor,name
          add_attribute Attribute.new(name, true, clazz)
        end
      end
    end

    include BelongsTo

    attr_accessor :id

    def initialize  hash={}, from_json = false
      initialize_has_attributes hash, from_json
    end

    def save
      if Source.skip_validations || self.valid?
        req_type = new_record? ? :post : :put

        success = !!AbstractResource::source.send(req_type, self)

        if success # check for special sub resources
          self.class.all_fields.find_all{|f| f.is_a?(HasManySubResourceAttribute)}.each do |attr|
            ids = self.send(attr.name)
            srifn = attr.sub_resource_field_name
            result = !!AbstractResource::source.put_sub_resource(self, srifn, ids)
            return false if !result
          end
          return true
        end
      end
      false
    end

    def new_record?
      [nil, ''].include?(id)
    end

    def delete
      AbstractResource::source().delete self
      true
    end
    #
    # convenience method printing curl command
    def curl
      hs = ""
      Arrest::Source.header_decorator.headers.each_pair do |k,v|
        hs << "-H '#{k}:#{v}'"
      end

      "curl #{hs} -v '#{Arrest::Source.source.url}/#{self.resource_location}'"
    end

    def == (comparison_object)
      other_class_name = comparison_object.class.name if comparison_object
      other_id = comparison_object.id if comparison_object
      self.class.name == other_class_name && self.id == other_id
    end
  end
end
