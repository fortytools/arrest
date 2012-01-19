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
    #assert_not_empty Arrest::AbstractResource.all_fields.select {|f| f.name == :id}, "AbstractResource defines the id field itself"
    #assert_not_empty Arrest::RootResource.all_fields.select {|f| f.name == :id}, "RootResource should inherit id from AbstractResource"
    #assert_not_empty Zoo.all_fields.select {|f| f.name == :id}, "Zoo should inherit id field from RootResource"
  end
  
  def test_create
    zoo_count_before = Zoo.all.length
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    zoo_count_after = Zoo.all.length
    assert_not_nil new_zoo.id

    assert_equal (zoo_count_before + 1), zoo_count_after
    assert new_zoo.id != nil

    zoo_the_last = Zoo.all.last
    assert_equal new_zoo.name, zoo_the_last.name
    assert_equal new_zoo.id, zoo_the_last.id

    zoo_reloaded = Zoo.find(new_zoo.id)
    assert_equal new_zoo.name, zoo_reloaded.name
    assert_equal new_zoo.id, zoo_reloaded.id
  end

  def test_prsnc_valid
    invalid_params = [
      {},
      {:name => nil},
      {:name => ''}
    ]

    invalid_params.each do |p|
      zoo_count_before = Zoo.all.length
      new_zoo = Zoo.new(p)
      assert_equal false, new_zoo.save, "zoo without name shouldnt be persistable"
      assert_equal zoo_count_before, Zoo.all.length
      assert_equal :name, new_zoo.errors.first[0]
      assert_nil new_zoo.id

      new_zoo.name = "Foo"

      assert new_zoo.save, "Creating should be possible after setting a name"
      zoo_count_after = Zoo.all.length
      assert_not_nil new_zoo.id

      assert_equal (zoo_count_before + 1), zoo_count_after
      assert new_zoo.id != nil

      new_zoo.name = ""
      assert_equal false, new_zoo.save, "Shouldnt be able to update without a name"
    end
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
    assert_not_nil zoo_reloaded
    assert_equal new_zoo.id, zoo_reloaded.id

    assert_equal new_zoo_name, zoo_reloaded.name
  end
  
  def test_child
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    assert_not_nil new_zoo.id
    #assert_not_nil new_zoo.class.all_fields.select {|f| f.name = :id}

    animal_kind = "mouse"
    new_animal = Animal.new new_zoo, {:kind => animal_kind, :age => 42}
    assert new_zoo.id != nil
    assert_equal new_zoo.id, new_animal.zoo.id
    assert_equal new_zoo.id, new_animal.parent.id

    new_animal.save

    assert new_animal.id != nil

    zoo_reloaded = Zoo.find(new_zoo.id)
    assert_equal new_zoo.id, zoo_reloaded.id
    assert_equal new_animal.parent.id, zoo_reloaded.id

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
    assert_equal "Foo", new_zoo.name
    assert_equal true, new_zoo.is_magic
    new_zoo.save

    assert new_zoo.id != nil, "Zoo must have id after save"
    zoo_reloaded = SpecialZoo.find(new_zoo.id)
    assert_equal new_zoo.id, zoo_reloaded.id
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
     
    hash = zoo.to_jhash

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
    assert stubbed.stubbed?, "Zoo should be a stub, so not loaded yet"
    new_name = stubbed.name
    assert !stubbed.stubbed?, "Zoo should not be a stub, so loaded now"

    assert_equal "Foo", new_name
  end

  def test_stub_not_load_for_child_access
    new_zoo = Zoo.new({:name => "Foo"})
    new_zoo.save
    
    assert_not_nil new_zoo.id
    # this is where the magic hapens
    stubbed = Zoo.stub(new_zoo.id)

    new_animal = Animal.new new_zoo, {:kind => "foo", :age => 42}
    new_animal.save
    
    assert stubbed.stubbed?, "Zoo should be a stub, so not loaded yet"

    animals = stubbed.animals

    assert stubbed.stubbed?, "Zoo should still be a stub, so not loaded yet"
    assert_equal 1, animals.length

    new_name = stubbed.name
    assert !stubbed.stubbed?, "Zoo should not be a stub, so loaded now"

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

    new_zoo2 = Zoo.new({:name => "Boo"})
    new_zoo2.save

    animal_kind = "mouse"
    Animal.new(new_zoo, {:kind => animal_kind, :age => 42, :male => true}).save
    Animal.new(new_zoo, {:kind => animal_kind, :age => 42, :male => false}).save
    Animal.new(new_zoo2, {:kind => animal_kind, :age => 42, :male => false}).save

    assert_equal 2, Zoo.all.first.animals.length
    assert_equal 1, Zoo.all.last.animals.length
    assert_equal 1, Zoo.all.first.animals.males_only.length
    assert_equal true, Zoo.all.first.animals.males_only.first.male

  end

  def test_para_filter
    p1 = ParentFilter.new({:afield => "Foo"})
    p2 = ParentFilter.new({:afield => "Bar"})
    p1.save
    p2.save

    nnn = ParentFilter.nnn("Foo")
    assert_equal ["Foo"], nnn.map(&:afield)
  end

  def test_para_filter_child
    p1 = ParentFilter.new({:afield => "ParentFoo"})
    p1.save

    c1 = ChildFilter.new(p1, :bfield => "Foo") 
    c1.save
    c2 = ChildFilter.new(p1, :bfield => "Bar") 
    c2.save

    reloaded_parent = ParentFilter.find(p1.id)
    assert_not_nil reloaded_parent
    assert_equal "ParentFoo", reloaded_parent.afield
    assert_equal 2, reloaded_parent.child_filters.length

    assert_equal ["Foo"], reloaded_parent.child_filters.child_nnn("Foo").map(&:bfield)
  end

  def test_no_param_filter
    p1 = ParentFilter.new({:afield => "Foo"})
    p2 = ParentFilter.new({:afield => "Bar"})
    p1.save
    p2.save

    no_param = ParentFilter.no_param
    assert_equal ["Foo"], no_param.map(&:afield)
  end

  def test_has_many
    Zoo.new(:name => "Foo1").save
    Zoo.new(:name => "Foo2").save
    assert_equal 2, Zoo.all.length
    all_zoo_ids = Zoo.all.map(&:id)
    v1 = ZooOwner.new({:name => "Foo", :zoo_ids => all_zoo_ids})
    v1.save

    v1_reloaded = ZooOwner.all.first
    assert_equal all_zoo_ids, v1_reloaded.zoo_ids

    url = v1.resource_location + '/' + Zoo.resource_name
    Arrest::Source.source.cheat_collection(url, v1_reloaded.zoo_ids)
    assert_equal 2,v1_reloaded.zoos.length
    assert_equal "Foo1", v1_reloaded.zoos.first.name
  end

  def test_build
    v1 = ZooOwner.new({:name => "Foo"})
    v1.save

    zoo = v1.zoos.build
    assert_equal v1.id, zoo.zoo_owner_id
  end

  def test_scope_has_many
    z1 = Zoo.new(:name => "Foo1", :open => true)
    z1.save
    z2 = Zoo.new(:name => "Foo2", :open => false)
    z2.save
    z3 = Zoo.new(:name => "Foo3", :open => true)
    z3.save
    assert_equal 3, Zoo.all.length
    all_zoo_ids = [z1.id, z2.id]
    v1 = ZooOwner.new({:name => "Foo", :zoo_ids => all_zoo_ids})
    v1.save

    v1_reloaded = ZooOwner.all.first
    assert_equal all_zoo_ids, v1_reloaded.zoo_ids

    url = v1.resource_location + '/' + Zoo.resource_name
    Arrest::Source.source.cheat_collection(url, v1_reloaded.zoo_ids)
    assert_equal 2,v1_reloaded.zoos.length
    assert_equal "Foo1", v1_reloaded.zoos.first.name

    assert_equal 1, v1_reloaded.zoos.open_filter.length
    assert_equal "Foo1", v1_reloaded.zoos.open_filter.first.name
    assert_equal 3, Zoo.all.length
  end

  def test_time
    now = Time.now
    expected = now.strftime "%FT%T%z"
    t = TimeClass.new(:time => now)
    assert_equal expected, t.to_jhash[:time], "This is the expected default format"
  end
  
  def test_polymorphic_belongs_to
    coma = CommentableA.new()
    coma.save
    comb = CommentableB.new()
    comb.save
    
    c = Comment.new(:commentable_ref => { :id => coma.id, :type => "coma"})
    result = c.commentable
    assert_equal coma.id, c.commentable_ref.id
    assert_equal result.class, CommentableA
    
    c2 = Comment.new(:commentable_ref => { :id => comb.id, :type => "comb"})
    result2 = c2.commentable
    assert_equal comb.id, c2.commentable_ref.id
    assert_equal result2.class, CommentableB
  end
  
  def test_polymorphic_belongs_to_extended
    coma = CommentableA.new()
    coma.save
    comc = CommentableC.new()
    comc.save
    
    c = ExtendedComment.new({ :special_commentable_ref => { :id => comc.id, :type => "comc"}, 
                              :commentable_ref => { :id => coma.id, :type => "coma" }})
    assert_equal c.commentable.class, CommentableA
    assert_equal c.other_commentable.class, CommentableC
    
    c.save
    c_reloaded = ExtendedComment.find(c.id)
    assert_equal comc.id, c_reloaded.special_commentable_ref.id
    assert_equal CommentableC, c_reloaded.other_commentable.class
    assert_equal CommentableA, c_reloaded.commentable.class
  end
  
  def test_delete_all_root_resources
    d1 = DeleteMeAll.new()
    d1.save
    d2 = DeleteMeAll.new()
    d2.save
    
    d1_rel = DeleteMeAll.find(d1.id)
    assert_not_nil d1_rel
    d2_rel = DeleteMeAll.find(d2.id)
    assert_not_nil d2_rel
    all = DeleteMeAll.all
    assert_equal 2, all.length
    
    DeleteMeAll.delete_all
    all = DeleteMeAll.all
    assert_equal [], all
  end
  
  def test_has_many_matrix_in_mem_source
    f1 = FooWithManyBars.new()
    f1.save
    f2 = FooWithManyBars.new()
    f2.save
    f3 = FooWithManyBars.new()
    f3.save
    

    b1 = BarWithManyFoos.new({:foo_ids => [f1.id, f2.id]})
    b1.save
    b2 = BarWithManyFoos.new({:foo_ids => [f2.id, f3.id]})
    b2.save
    
    f1.delete
    
    b1_rel = BarWithManyFoos.find(b1.id)
    #assert_equal [f2.id], b1_rel.foo_ids
    
    #f2.delete
    #b1_rel = BarWithManyFoos.find(b1.id)
    #assert_equal [], b1_rel.foo_ids
    #b2_rel = BarWithManyFoos.find(b2.id)
    #assert_equal [f3.id], b2_rel.foo_ids
  end
end

