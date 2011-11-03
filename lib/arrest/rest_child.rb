module Arrest
  class RestChild < AbstractResource
    attr_accessor :parent
    def initialize parent
      @parent = parent
    end

    class << self
      # class method to generate path to a child resource of aonther resource
      def resource_path_for parent
        "#{parent.location}/#{self.resource_name}"
      end


      def all_for parent
        body_root(source().get self.resource_path_for(parent)).map do |h|
          self.build(parent, h)
        end
      end

      def find_for parent,id
        r = source().get "#{self.resource_path_for(parent)}/#{id}"
        body = body_root(r)
        self.build body
      end

    end

    # instance method to generate path to a child resource of another resource
    def resource_path
      self.class.resource_path_for @parent
    end

    # unique url for one instance of this class
    def location
      "#{self.class.resource_path}/#{self.id.to_s}"
    end


  end
end

