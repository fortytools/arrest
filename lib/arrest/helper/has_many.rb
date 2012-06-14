module Arrest
  module HasMany
    include Arrest::HasAttributes

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def has_many(*args)
        method_name, options = args
        ids_field_name = (StringUtils.singular(method_name.to_s) + '_ids').to_sym
        method_name = method_name.to_sym
        clazz_name = StringUtils.singular(method_name.to_s)
        foreign_key = clazz_name + "_id"
        sub_resource = false
        read_only = false
        url_part = "/" + method_name.to_s
        if options
          clazz_name = options[:class_name].to_s unless options[:class_name] == nil
          foreign_key = "#{StringUtils.underscore(clazz_name)}_id"
          foreign_key = options[:foreign_key].to_s unless options[:foreign_key] == nil
          sub_resource = !!options[:sub_resource]
          read_only = options[:read_only]
          url_part = "/" + options[:url_part].to_s unless options[:url_part] == nil
        end

        hm_attr = create_has_many_attribute(sub_resource, # e.g. 'team_ids' attribute for 'has_many :teams'
                                            ids_field_name,
                                            method_name,
                                            clazz_name,
                                            url_part,
                                            foreign_key,
                                            read_only)
        add_attribute(hm_attr)
        send :define_method, method_name do |filter = {}|# e.g. define 'teams' method for notation 'has_many :teams'
          HasManyCollection.new(self, self.context, clazz_name, self.resource_location + url_part.to_s, filter)
        end
      end

      def create_has_many_attribute(sub_resource, ids_field_name, method_name,
                                    clazz_name, url_part, foreign_key, read_only)
        if sub_resource
          define_attribute_methods [ids_field_name]
          return HasManySubResourceAttribute.new(ids_field_name,
                                                 method_name,
                                                 clazz_name,
                                                 url_part,
                                                 foreign_key,
                                                 read_only)
        else
          return HasManyAttribute.new(ids_field_name,
                                      method_name,
                                      clazz_name,
                                      url_part,
                                      foreign_key,
                                      read_only)
        end
      end
    end

  end
end
