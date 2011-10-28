module Arrest
  class AbstractResource
    extend ActiveModel::Naming

    attr_accessor :keys
    attr_accessor :generic
    cattr_accessor :SOURCE
    @@SOURCE = SGDB[:SOURCE]

    def initialize
      @generic = false
    end

    class << self

      def source
        if @@SOURCE.blank?
          @@SOURCE = SGDB[:SOURCE]
        end
        @@SOURCE
      end


      def body_root response
        all = JSON.parse response
        all["results"]
      end

      def build hash
        o = self.new
        o.generic = true
        o.keys = []
        sing = o.singleton_class
        hash.each_pair do |key, value| 
          name = key.to_s.gsub(/^[^a-zA-Z]/, '')
          o.keys << name
          if value.is_a? Hash
            p = Properties.new value
            sing.send(:define_method, name) { p }
          else
            sing.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}; #{value.nil? ? 'nil' : value.to_s.inspect}; end
            RUBY
          end
            sing.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def to_s; base_to_s(); end
            RUBY
        end
        o
      end

      def resource_name
        self.name.downcase.pluralize
      end
    end

    def save
      if self.respond_to?(:id) && self.id.present?
        AbstractResource::source().put self
      else
        AbstractResource::source().post self
      end
    end


    def to_hash
      raise "if build is defined in subclass, also define to_hash in subclass" unless @generic
      r = {}
      @keys.each do |key|
        r[key] = self.send(key)
      end
      r
    end

    def base_to_s
      strs = @keys.map do |k|
        "'#{k}' => #{self.send(k.to_s)}"
      end
      "{#{strs.join(',')}}"
    end
  end
end
