module Arrest
  # A nested resource has no own url
  # It is an embedded entity in an actual RestResource or
  # an other NestedResource
  class NestedResource
    include HasAttributes

    def initialize h
      init_from_hash h
    end

    class << self
      def to_hash
        result = {}
        unless self.class.all_fields == nil
          self.class.all_fields.find_all{|a| !a.read_only}.each do |field|
            json_name = StringUtils.classify(field.name.to_s,false)
            result[json_name] = self.instance_variable_get("@#{field.name.to_s}")
          end
        end
        result[:id] = self.id
        result

      end

    end
  end
end
