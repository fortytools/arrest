module Arrest
  module HasMany
    include Arrest::HasAttributes

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_many(*args)                                                                 # has_many :my_teams, :class_name => :Team
        method_name, options = args                                                       # my_teams
        ids_method_name = (StringUtils.singular(method_name.to_s) + '_ids').to_sym        # my_team_ids
        method_name = method_name.to_sym                                                  # :my_teams

        clazz_name = StringUtils.singular(method_name.to_s)                               # my_team

        ids_method_url_part = "/" + ids_method_name.to_s                                  # /my_team_ids
        method_url_part = "/" + method_name.to_s                                          # /my_teams

        read_only = false
        if options
          clazz_name = options[:class_name].to_s unless options[:class_name] == nil       # :Team
          foreign_key = "#{StringUtils.underscore(clazz_name)}_id"                        # team_id
          foreign_key = options[:foreign_key].to_s unless options[:foreign_key] == nil    # team_id
          ids_method_url_part = "/" + options[:url_part].to_s unless options[:url_part] == nil # /my_url_part_ids
          method_url_part     = "/" + options[:url_part].to_s unless options[:url_part] == nil # /my_url_part
          read_only = !!options[:read_only] unless options[:read_only] == nil
        end


        if read_only
          send(:define_method, ids_method_name) do |filter = {}|
            IdsCollection.new(self, self.resource_location + ids_method_url_part)
          end
        else
          self.attribute ids_method_name.to_sym, Array
        end

        send(:define_method, method_name) do |filter = {}|
          HasManyCollection.new(self, self.context, clazz_name, self.resource_location + method_url_part, filter)
        end
      end
    end

  end
end
