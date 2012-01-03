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

      def scoped_path_for parent, scope_name
        (resource_path_for parent) + '/' + scope_name.to_s
      end

      def build parent, hash
        self.new parent, hash
      end


      def all_for parent
        raise "Parent has no id yet" unless parent.id
        begin
          body_root(source().get_many self.resource_path_for(parent)).map do |h|
            self.build(parent, h)
          end
        rescue Arrest::Errors::DocumentNotFoundError
          []
        end
      end

      def find id
        raise "find cannot be executed for child resources - use find_for with a parent"
      end

      def find_for parent,id
        r = source().get_one "#{self.resource_path_for(parent)}/#{id}"
        body = body_root(r)
        self.build body
      end

      def filter name, &aproc
        if aproc != nil
          send :define_singleton_method, name do |*args|
            self.all_for(args[0]).select do |instance|
              instance.instance_exec(*(args.drop(1)), &aproc)
            end
          end
        else
          raise "You must specify a block for a filter"
        end
      end

      def scope name, &block
        super name
        if block_given?
          send :define_singleton_method, name do |parent|
            self.all_for(parent).select &block 
          end
        else
          send :define_singleton_method, name do |parent|
            raise "Parent has no id yet" unless parent.id
            body_root(source().get_many self.scoped_path_for(parent, name)).map do |h|
              self.build(parent, h)
            end
          end
        end

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

    def unstub
      return unless @stub
      raise "stubbing for child resource isnt supported yet"
    end


  end
end

