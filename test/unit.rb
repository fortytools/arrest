require 'arrest'
require 'test/unit'

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
  read_only_attributes({ :ro2 => String})
  attributes({ 
    :is_magic => Boolean,
    :opened_at => Time
  })

end

class FirstTest < Test::Unit::TestCase

  def setup
     Arrest::Source.source = nil
  end

  def test_mem_src
     Arrest::Source.source = nil
     src = Arrest::Source.source
     assert_equal Arrest::MemSource, src.class
  end

  def test_init
    zooname =  "Hagenbecks"
    z = Zoo.new({:name => zooname})
    assert_equal zooname, z.name
  end
  
  def test_create
    zoo_count_before = Zoo.all.length
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    zoo_count_after = Zoo.all.length

    assert_equal (zoo_count_before + 1), zoo_count_after
    assert new_zoo.id != nil

    zoo_the_last = Zoo.all.last
    assert_equal new_zoo.name, zoo_the_last.name

    zoo_reloaded = Zoo.find(new_zoo.id)
    assert_equal new_zoo.name, zoo_reloaded.name
  end

  def test_delete
    zoo_count_before = Zoo.all.length
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    zoo_count_after = Zoo.all.length

    assert_equal (zoo_count_before + 1), zoo_count_after
    assert new_zoo.id != nil

    zoo_the_last = Zoo.all.last
    assert_equal new_zoo.name, zoo_the_last.name

    zoo_reloaded = Zoo.find(new_zoo.id)
    assert_equal new_zoo.name, zoo_reloaded.name
    
    zoo_reloaded.delete
    assert_equal zoo_count_before, Zoo.all.length
  end

  def test_create_and_load
    zoo_count_before = Zoo.all.length
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    zoo_count_after = Zoo.all.length

    assert_equal (zoo_count_before + 1), zoo_count_after
  end

  def test_update
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save

    new_zoo_name = "Hagenbecks"
    new_zoo.name = new_zoo_name
    new_zoo.save

    assert new_zoo.id != nil

    zoo_reloaded = Zoo.find(new_zoo.id)

    assert_equal new_zoo_name, zoo_reloaded.name
  end
  
  def test_child
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save

    animal_kind = "mouse"
    new_animal = Animal.new new_zoo, {:kind => animal_kind, :age => 42}
    assert new_zoo.id != nil
    assert_equal new_zoo.id, new_animal.zoo.id
    assert_equal new_zoo.id, new_animal.parent.id

    new_animal.save

    assert new_animal.id != nil

    zoo_reloaded = Zoo.find(new_zoo.id)


    assert_equal 1, zoo_reloaded.animals.length
    assert_equal 42, zoo_reloaded.animals.first.age
    
    animal_reloaded = zoo_reloaded.animals.first

    assert_equal new_zoo.id, animal_reloaded.zoo.id

    assert_equal animal_kind, zoo_reloaded.animals.first.kind
  end

  def test_child_update
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save

    animal_kind = "mouse"
    new_animal = Animal.new new_zoo, {:kind => "foo", :age => 42}
    new_animal.save

    animal_reloaded = new_zoo.animals.first
    animal_reloaded.kind = animal_kind
    animal_reloaded.save

    assert_equal animal_kind, animal_reloaded.kind

    animal_retry = new_zoo.animals.last
    assert_equal animal_kind, animal_retry.kind
  end

  def test_inheritance
    new_zoo = SpecialZoo.new({:name => "Foo", :is_magic => true})
    new_zoo.save

    assert new_zoo.id != nil, "Zoo must have id after save"
    zoo_reloaded = SpecialZoo.find(new_zoo.id)
    assert_equal true, zoo_reloaded.is_magic
    assert_equal "Foo", zoo_reloaded.name
  end

  def test_inheritance_update
    new_zoo = SpecialZoo.new({:name => "Foo", :is_magic => true})
    new_zoo.save

    assert new_zoo.id != nil, "Zoo must have id after save"
    zoo_reloaded = SpecialZoo.find(new_zoo.id)
    assert_equal true, zoo_reloaded.is_magic
    assert_equal "Foo", zoo_reloaded.name

    new_name = "Bar"
    zoo_reloaded.name = new_name
    zoo_reloaded.is_magic = !zoo_reloaded.is_magic
    zoo_reloaded.save

    updated_zoo = SpecialZoo.find(zoo_reloaded.id)
    assert_equal new_name, updated_zoo.name
    assert_equal !new_zoo.is_magic, updated_zoo.is_magic
  end

  def test_read_only_attributes
    now = Time.now
    zoo = SpecialZoo.new({
      :name => "Zoo", 
      :ro1 => "one", 
      :ro2 => "two", 
      :is_magic => true,
      :opened_at => now
    })
    
    assert_equal "Zoo", zoo.name
    assert_equal "one", zoo.ro1
    assert_equal "two", zoo.ro2
    assert_equal true, zoo.is_magic
     
    hash = zoo.to_hash

    assert_nil hash[:ro1]
    assert_nil hash[:ro2]
    assert_equal Time, zoo.opened_at.class
    assert_equal now, zoo.opened_at

  end
end

