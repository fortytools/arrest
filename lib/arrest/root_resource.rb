module Arrest
  class RootResource < AbstractResource

    class << self

      def resource_path
        "#{self.resource_name}"
      end

      def all
        body_root(source().get self.resource_path).map do |h|
          self.build h
        end
      end

      def find id
        r = source().get "#{self.resource_path}/#{id}"
        body = body_root(r)
        self.build body
      end

    end

    def resource_path
      "#{self.class.resource_name}"
    end

    def location
      self.class.resource_path + '/' + self.id.to_s 
    end

  end
end

