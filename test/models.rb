require 'arrest'

class Zoo < Arrest::RootResource
  attributes({ :name => String })
  read_only_attributes({ :ro1 => String})
  has_many :animals
end

class Animal < Arrest::RestChild
  attributes({
    :kind => String,
    :age => Integer
  })
  parent :zoo
end

class SpecialZoo < Zoo
  custom_resource_name :zoo3000
  read_only_attributes({ :ro2 => String})
  attributes({ 
    :is_magic => Boolean,
    :opened_at => Time
  })

end

