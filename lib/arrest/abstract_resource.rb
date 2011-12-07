require 'json'
require 'arrest/string_utils'
require 'time'

Scope = Struct.new(:name, :block)

module Arrest
  class AbstractResource
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
        underscored_hash = {}
        hash.each_pair do |k, v|
          underscored_hash[StringUtils.underscore k] = v
        end
        self.new underscored_hash
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

    def initialize  hash={}
      initialize_has_attributes hash
    end

    def save
      verb = new_record? ? :post : :put
      !!AbstractResource::source.send(verb, self)
    end

    def new_record?
      [nil, ''].include?(id)
    end

    def delete
      AbstractResource::source().delete self
      true
    end
    #
    # convenicence method printing curl command
    def curl
      hs = ""
      Arrest::Source.header_decorator.headers.each_pair do |k,v| 
        hs << "-H '#{k}:#{v}'"
      end

      "curl #{hs} -v '#{Arrest::Source.source.url}/#{self.resource_location}'"
    end
  end
end
