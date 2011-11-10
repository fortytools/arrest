module Arrest
  class RestChild < AbstractResource
    attr_accessor :parent
    def initialize parent, h
      super h
      @parent = parent
    end

    class << self
      # class method to generate path to a child resource of aonther resource
      def resource_path_for parent
        "#{parent.resource_location}/#{self.resource_name}"
      end

      def build parent, hash
        self.new parent, hash
      end


      def all_for parent
        raise "Parent has no id yet" unless parent.id
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
    def resource_location
      "#{self.class.resource_path}/#{self.id.to_s}"
    end


  end
end

