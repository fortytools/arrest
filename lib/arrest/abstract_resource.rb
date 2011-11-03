module Arrest
  class AbstractResource
    extend ActiveModel::Naming

    attr_accessor :keys

    class << self

      def source
        Arrest::Source::source
      end


      def body_root response
        all = JSON.parse response
        all["results"]
      end

      def build hash
        raise "override in subclass with a method, that converts the given hash to an object of the desired class"
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
      raise "override symmetrically to build, to create a hash representation from self"
    end

  end
end
