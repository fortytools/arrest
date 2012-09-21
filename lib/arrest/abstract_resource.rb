require 'json'
require 'time'
require 'active_model'

Scope = Struct.new(:name, :options, :block)

module Arrest

  class AbstractResource
    extend ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::Validations::Callbacks
    extend ActiveModel::Callbacks
    extend ActiveModel::Translation
    include HasAttributes
    include HasMany
    include HasView
    attribute :id, String

    attr_accessor :context

    @@POLYMORPHIC_TYPE_MAP = {}

    class << self
      attr_reader :scopes

      def inherited(child)
        ScopedRoot::register_resource(child)
        @@POLYMORPHIC_TYPE_MAP[ClassUtils.simple_name(child).to_sym] = child
      end

      def mk_proxy(context_provider)
        ResourceProxy.new(self, context_provider)
      end

      def source
        Arrest::Source::source
      end

      def body_root(response)
        ::ActiveSupport::Notifications.instrument("parse.sgdb",
                                              :length => response.length) do
          if response == nil
            raise Errors::DocumentNotFoundError
          end
          all = JSON.parse(response)
          body = all["result"]
          if body == nil
            raise Errors::DocumentNotFoundError
          end
          body
        end
      end

      def build(context, hash)
        resource = self.new(context, hash, true)
        resource
      end

      def custom_resource_name(new_name)
        @custom_resource_name = new_name
      end

      def resource_name
        if @custom_resource_name
          @custom_resource_name
        else
          simple_name = ClassUtils.simple_name(self)
          usd_name = StringUtils.underscore(simple_name)
          StringUtils.plural(usd_name)
        end
      end

      def parent(*args)
        method_name = args[0].to_s.to_sym
        class_eval "def #{method_name}; self.parent; end"
      end

      def scope(name, options = {}, &block)
        if @scopes == nil
          @scopes = []
        end
        @scopes << Scope.new(name, options, &block)
      end


      def read_only_attributes(args)
        args.each_pair do |name, clazz|
          self.send :attr_accessor,name
          add_attribute(Attribute.new(name, clazz, [:retrieve]))
        end
      end

      def filters
        @filters
      end

      def all_filters
        all_filters = @filters
        all_filters ||= []
        if superclass.respond_to?('filters') && superclass.filters
          all_fields += superclass.filters
        end
        all_filters
      end

      def json_type_map
        @@POLYMORPHIC_TYPE_MAP
      end

      def custom_json_type(new_key)
        old_key = Arrest::ClassUtils.simple_name(self).to_sym
        value = @@POLYMORPHIC_TYPE_MAP.delete(old_key) # remove default key for self
        @@POLYMORPHIC_TYPE_MAP[new_key.to_sym] = value # add custom key for type
      end

      def json_type_to_class(type)
        @@POLYMORPHIC_TYPE_MAP[type.to_sym]
      end

      def to_json_type
        @@POLYMORPHIC_TYPE_MAP.invert[self]
      end

      def active_resource_classes
        @@POLYMORPHIC_TYPE_MAP.values
      end
    end

    def to_json_type
      self.class.to_json_type
    end

    include BelongsTo

    attr_accessor :id

    def initialize(context, hash={}, from_json = false)
      @context = context
      initialize_has_attributes(hash, from_json)
    end

    def save
      if Source.skip_validations || self.valid?
        req_type = new_record? ? :post : :put
        success = !!AbstractResource::source.send(req_type, @context, self)
        self.context.cache.flush
        self.reset_dirtiness
        success
      else
        false
      end
    end

    def save!
      raise self.errors.inspect unless self.save
    end

    def clone
      self.class.new(self.context, self.to_hash)
    end

    def reload
      @child_collections = {}
      @views = {}
      @belongs_tos = {}
      hash = internal_reload
      self.attributes= hash
      self.reset_dirtiness
    end

    def new_record?
      [nil, ''].include?(id)
    end

    def delete
      self.context.cache.flush
      AbstractResource::source().delete(@context, self)
    end

    # convenience method printing curl command
    def curl
      hs = ""
      self.context.header_decorator.headers.each_pair do |k,v|
        hs << " -H '#{k}:#{v}' "
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
