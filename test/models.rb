require 'arrest'

class Zoo < Arrest::RootResource
  attributes({ :name => String , :open => Boolean})
  read_only_attributes({ :ro1 => String})
  has_many :animals

  scope :server_scope
  scope(:open) { |z| z.open }
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

