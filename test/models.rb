require 'arrest'

class Zoo < Arrest::RootResource
  attributes({ :name => String , :open => Boolean})
  read_only_attributes({ :ro1 => String})
  has_many :animals

  scope :server_scope
  scope(:open) { |z| z.open }

  validates_presence_of :name
end

class Animal < Arrest::RestChild
  attribute :kind, String
  attribute :age, Integer
  attribute :male, Boolean
  
  parent :zoo

  scope :server_males_only
  scope(:males_only){|a| a.male}
end

class SpecialZoo < Zoo
  custom_resource_name :zoo3000
  read_only_attributes({ :ro2 => String})
  attributes({ 
    :is_magic => Boolean,
    :opened_at => Time
  })

end

class ANestedClass < Arrest::NestedResource
  attribute :name, String
  attribute :underscore_name, String
  attribute :bool, Boolean
end

class WithNested < Arrest::RootResource
  attribute :parent_name, String
  attribute :bool, Boolean
  nested :nested_object, ANestedClass
end

class WithManyNested < Arrest::RootResource
  attribute :parent_name, String
  attribute :bool, Boolean
  nested_array :nested_objects, ANestedClass
end


class ANestedClassBelonging < Arrest::NestedResource
  attribute :name, String
  attribute :bool, Boolean

  belongs_to :zoo
end

class WithNestedBelongingTo < Arrest::RootResource
  attribute :parent_name, String
  attribute :bool, Boolean
  nested :nested_object, ANestedClassBelonging
end

class CustomNamedBelongsTo < Arrest::RootResource
  attribute :name, String
  belongs_to :zoo_thing, { :field_name => :schinken, :class_name => :Zoo}
  belongs_to :zoo, { :field_name => :batzen}
end

class ParentFilter < Arrest::RootResource
  attribute :id, String
  attribute :afield, String

  filter(:nnn) {|s| afield == s}
  filter(:no_param){ afield == "Foo"}
  filter(:running){ afield == "Foo"}
  has_many :child_filters
end

class ChildFilter < Arrest::RestChild
  attribute :id, String
  attribute :bfield, String

  parent :parent_filter

  filter(:child_nnn) {|s| bfield == s}
end
