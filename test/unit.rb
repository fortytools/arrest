require 'test/unit'
load 'test/models.rb'

class FirstTest < Test::Unit::TestCase

  def setup
     Arrest::Source.source = nil
     #Arrest::Source.debug = true
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
    assert_equal Animal, zoo_reloaded.animals.first.class
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
    assert_equal :zoo3000, SpecialZoo.resource_name

    new_zoo = SpecialZoo.new({:name => "Foo", :is_magic => true})
    new_zoo.save

    assert new_zoo.id != nil, "Zoo must have id after save"
    zoo_reloaded = SpecialZoo.find(new_zoo.id)
    assert_equal true, zoo_reloaded.is_magic
    assert_equal "Foo", zoo_reloaded.name

    new_name = "Bar"
    zoo_reloaded.name = new_name
    old_is_magic = zoo_reloaded.is_magic
    zoo_reloaded.is_magic = !zoo_reloaded.is_magic
    zoo_reloaded.save

    updated_zoo = SpecialZoo.find(zoo_reloaded.id)
    assert_equal new_name, updated_zoo.name
    assert_equal !old_is_magic, updated_zoo.is_magic
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

  def test_stub_delayed_load
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    
    assert_not_nil new_zoo.id

    stubbed = Zoo.stub(new_zoo.id)
    assert stubbed.stub, "Zoo should be a stub, so not loaded yet"
    new_name = stubbed.name
    assert !stubbed.stub, "Zoo should not be a stub, so loaded now"

    assert_equal "Foo", new_name
  end

  def test_stub_not_load_for_child_access
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    
    assert_not_nil new_zoo.id
    # this is where the magic hapens
    stubbed = Zoo.stub(new_zoo.id)
    return

    new_animal = Animal.new new_zoo, {:kind => "foo", :age => 42}
    new_animal.save
    
    assert stubbed.stub, "Zoo should be a stub, so not loaded yet"

    animals = stubbed.animals

    assert stubbed.stub, "Zoo should still be a stub, so not loaded yet"
    assert_equal 1, animals.length

    new_name = stubbed.name
    assert !stubbed.stub, "Zoo should not be a stub, so loaded now"

    assert_equal "Foo", new_name
    

  end

  def test_root_scope
    assert_not_nil Zoo.server_scope
  end
  
  def test_child_scope
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    
    assert_not_nil new_zoo.id

    assert_not_nil new_zoo.animals.server_males_only
  end

  def test_local_scope

    zoo_false = Zoo.new({:name => "Foo", :open => false})
    zoo_false.save
    zoo_true = Zoo.new({:name => "Foo", :open => true})
    zoo_true.save

    assert_equal 1, Zoo.open.length
    assert_equal true, Zoo.open.first.open
  end

  def test_local_child_scope
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save

    animal_kind = "mouse"
    Animal.new(new_zoo, {:kind => animal_kind, :age => 42, :male => true}).save
    Animal.new(new_zoo, {:kind => animal_kind, :age => 42, :male => false}).save

    assert_equal 2, Zoo.all.first.animals.length
    assert_equal 1, Zoo.all.first.animals.males_only.length
    assert_equal true, Zoo.all.first.animals.males_only.first.male

  end
end

