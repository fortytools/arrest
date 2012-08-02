require 'arrest'

class Zoo < Arrest::RootResource
  attributes({ :name => String , :open => Boolean})
  read_only_attributes({ :ro1 => String})
  children :animals

  scope :server_scope
  scope(:open) { |z| z.open }
  filter(:open_filter) { open }

  validates_presence_of :name

  belongs_to :zoo_owner
end

class Animal < Arrest::RootResource
  attribute :kind, String
  attribute :age, Integer
  attribute :male, Boolean

  belongs_to :zoo

  scope :server_males_only
  scope(:males_only){|a| a.male}
end

class ZooOwner < Arrest::RootResource
  attribute :name, String
  has_many :zoos
end


class SpecialZoo < Zoo
  custom_resource_name :zoo3000
  read_only_attributes({ :ro2 => String})
  attributes({
    :is_magic => Boolean,
    :opened_at => Time
  })

end

class TimeClass < Arrest::RootResource
  attribute :time, Time
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
  children :child_filters
end

class ChildFilter < Arrest::RootResource
  attribute :id, String
  attribute :bfield, String

  belongs_to :parent_filter

  filter(:child_nnn) {|s| bfield == s}
end

class CommentableA < Arrest::RootResource
end
class CommentableB < Arrest::RootResource
end
class CommentableC < Arrest::RootResource
end
class CommentableD < Arrest::RootResource
  custom_json_type :ComD
end
class Comment < Arrest::RootResource
  belongs_to :commentable, :polymorphic => true
end
class ExtendedComment < Comment
  belongs_to :other_commentable,
             :field_name => "special_commentable_ref",
             :polymorphic => true
end

class DeleteMeAll < Arrest::RootResource
end

class Foo < Arrest::RootResource
  has_many :bars#, :class_name => :Bar, :foreign_key => defaults to bar_id
  has_many :other_bars, :class_name => :Bar, :foreign_key => :common_key
end
class Bar < Arrest::RootResource
  has_many :foos
  belongs_to :foo# foreign key defaults to class name, {:foreign_key => bar_id}
  belongs_to :other_foo, {:class_name => Foo, :foreign_key => :common_key}#, :foreign_key => :other_foo_key
end

class BarWithHasManySubResource < Arrest::RootResource
  has_many :foos, :sub_resource => true
end
