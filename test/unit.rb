require 'test/unit'
load 'test/models.rb'

class FirstTest < Test::Unit::TestCase

  def setup
     Arrest::Source.source = nil
     @scope = Arrest::ScopedRoot.new
     #Arrest::Source.debug = true
  end

  def test_mem_src
     Arrest::Source.source = nil
     src = Arrest::Source.source
     assert_equal Arrest::MemSource, src.class
  end

  def test_init
    zooname =  "Hagenbecks"
    z = @scope.Zoo.new({:name => zooname})
    assert_equal zooname, z.name
    #assert_not_empty Arrest::AbstractResource.all_fields.select {|f| f.name == :id}, "AbstractResource defines the id field itself"
    #assert_not_empty Arrest::RootResource.all_fields.select {|f| f.name == :id}, "RootResource should inherit id from AbstractResource"
    #assert_not_empty @scope.Zoo.all_fields.select {|f| f.name == :id}, "Zoo should inherit id field from RootResource"
  end

  def test_create
    zoo_count_before = @scope.Zoo.all.length
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    assert_equal "Foo", new_zoo.name
    assert new_zoo.save, new_zoo.errors.full_messages.to_s
    zoo_count_after = @scope.Zoo.all.length
    assert_not_nil new_zoo.id

    assert_equal (zoo_count_before + 1), zoo_count_after
    assert new_zoo.id != nil

    zoo_the_last = @scope.Zoo.all.last
    assert_equal new_zoo.name, zoo_the_last.name
    assert_equal new_zoo.id, zoo_the_last.id

    zoo_reloaded = @scope.Zoo.find(new_zoo.id)
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
      zoo_count_before = @scope.Zoo.all.length
      new_zoo = @scope.Zoo.new(p)
      assert_equal false, new_zoo.save, "zoo without name shouldnt be persistable"
      assert_equal zoo_count_before, @scope.Zoo.all.length
      assert_equal :name, new_zoo.errors.first[0]
      assert_nil new_zoo.id

      new_zoo.name = "Foo"

      assert new_zoo.save, "Creating should be possible after setting a name"
      zoo_count_after = @scope.Zoo.all.length
      assert_not_nil new_zoo.id

      assert_equal (zoo_count_before + 1), zoo_count_after
      assert new_zoo.id != nil

      new_zoo.name = ""
      assert_equal false, new_zoo.save, "Shouldnt be able to update without a name"
    end
  end

  def test_delete
    zoo_count_before = @scope.Zoo.all.length
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save
    zoo_count_after = @scope.Zoo.all.length

    assert_equal (zoo_count_before + 1), zoo_count_after
    assert new_zoo.id != nil

    zoo_the_last = @scope.Zoo.all.last
    assert_equal new_zoo.name, zoo_the_last.name

    zoo_reloaded = @scope.Zoo.find(new_zoo.id)
    assert_equal new_zoo.name, zoo_reloaded.name

    zoo_reloaded.delete
    assert_equal zoo_count_before, @scope.Zoo.all.length
  end

  def test_create_and_load
    zoo_count_before = @scope.Zoo.all.length
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save
    zoo_count_after = @scope.Zoo.all.length

    assert_equal (zoo_count_before + 1), zoo_count_after
  end

  def test_update
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    new_zoo_name = "Hagenbecks"
    new_zoo.name = new_zoo_name
    new_zoo.save

    assert new_zoo.id != nil

    zoo_reloaded = @scope.Zoo.find(new_zoo.id)
    assert_not_nil zoo_reloaded
    assert_equal new_zoo.id, zoo_reloaded.id

    assert_equal new_zoo_name, zoo_reloaded.name
  end

  def test_child
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save
    assert_not_nil new_zoo.id
    #assert_not_nil new_zoo.class.all_fields.select {|f| f.name = :id}

    animal_kind = "mouse"
    new_animal = @scope.Animal.new new_zoo, {:kind => animal_kind, :age => 42}
    assert new_zoo.id != nil
    assert_equal new_zoo.id, new_animal.zoo.id
    assert_equal new_zoo.id, new_animal.parent.id

    new_animal.save

    assert new_animal.id != nil

    zoo_reloaded = @scope.Zoo.find(new_zoo.id)
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
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    animal_kind = "mouse"
    new_animal = @scope.Animal.new new_zoo, {:kind => "foo", :age => 42}
    new_animal.save

    animal_reloaded = new_zoo.animals.first
    animal_reloaded.kind = animal_kind
    animal_reloaded.save

    assert_equal animal_kind, animal_reloaded.kind

    animal_retry = new_zoo.animals.last
    assert_equal animal_kind, animal_retry.kind
  end

  def test_inheritance
    new_zoo = @scope.SpecialZoo.new({:name => "Foo", :is_magic => true})
    assert_equal "Foo", new_zoo.name
    assert_equal true, new_zoo.is_magic
    new_zoo.save

    assert new_zoo.id != nil, "Zoo must have id after save"
    zoo_reloaded = @scope.SpecialZoo.find(new_zoo.id)
    assert_equal new_zoo.id, zoo_reloaded.id
    assert_equal true, zoo_reloaded.is_magic
    assert_equal "Foo", zoo_reloaded.name
  end

  def test_inheritance_update
    assert_equal :zoo3000, SpecialZoo.resource_name

    new_zoo = @scope.SpecialZoo.new({:name => "Foo", :is_magic => true})
    new_zoo.save

    assert new_zoo.id != nil, "Zoo must have id after save"
    zoo_reloaded = @scope.SpecialZoo.find(new_zoo.id)
    assert_equal true, zoo_reloaded.is_magic
    assert_equal "Foo", zoo_reloaded.name

    new_name = "Bar"
    zoo_reloaded.name = new_name
    old_is_magic = zoo_reloaded.is_magic
    zoo_reloaded.is_magic = !zoo_reloaded.is_magic
    zoo_reloaded.save

    updated_zoo = @scope.SpecialZoo.find(zoo_reloaded.id)
    assert_equal new_name, updated_zoo.name
    assert_equal !old_is_magic, updated_zoo.is_magic
  end

  def test_read_only_attributes
    now = Time.now
    zoo = @scope.SpecialZoo.new({
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
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    assert_not_nil new_zoo.id

    stubbed = @scope.Zoo.stub(new_zoo.id)
    assert stubbed.stubbed?, "Zoo should be a stub, so not loaded yet"
    new_name = stubbed.name
    assert !stubbed.stubbed?, "Zoo should not be a stub, so loaded now"

    assert_equal "Foo", new_name
  end

  def test_stub_not_load_for_child_access
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    assert_not_nil new_zoo.id
    # this is where the magic hapens
    stubbed = @scope.Zoo.stub(new_zoo.id)

    new_animal = @scope.Animal.new new_zoo, {:kind => "foo", :age => 42}
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
    assert_not_nil @scope.Zoo.server_scope
  end

  def test_child_scope
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    assert_not_nil new_zoo.id

    assert_not_nil new_zoo.animals.server_males_only
  end

  def test_local_scope

    zoo_false = @scope.Zoo.new({:name => "Foo", :open => false})
    zoo_false.save
    zoo_true = @scope.Zoo.new({:name => "Foo", :open => true})
    zoo_true.save

    assert_equal 1, @scope.Zoo.open.length
    assert_equal true, @scope.Zoo.open.first.open
  end

  def test_local_child_scope
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    new_zoo2 = @scope.Zoo.new({:name => "Boo"})
    new_zoo2.save

    animal_kind = "mouse"
    @scope.Animal.new(new_zoo, {:kind => animal_kind, :age => 42, :male => true}).save
    @scope.Animal.new(new_zoo, {:kind => animal_kind, :age => 42, :male => false}).save
    @scope.Animal.new(new_zoo2, {:kind => animal_kind, :age => 42, :male => false}).save

    assert_equal 2, @scope.Zoo.all.first.animals.length
    assert_equal 1, @scope.Zoo.all.last.animals.length
    assert_equal 1, @scope.Zoo.all.first.animals.males_only.length
    assert_equal true, @scope.Zoo.all.first.animals.males_only.first.male

  end

  def test_para_filter
    p1 = @scope.ParentFilter.new({:afield => "Foo"})
    p2 = @scope.ParentFilter.new({:afield => "Bar"})
    p1.save
    p2.save

    nnn = @scope.ParentFilter.nnn("Foo")
    assert_equal ["Foo"], nnn.map(&:afield)
  end

  def test_para_filter_child
    p1 = @scope.ParentFilter.new({:afield => "ParentFoo"})
    p1.save

    c1 = @scope.ChildFilter.new(p1, :bfield => "Foo")
    c1.save
    c2 = @scope.ChildFilter.new(p1, :bfield => "Bar")
    c2.save

    reloaded_parent = @scope.ParentFilter.find(p1.id)
    assert_not_nil reloaded_parent
    assert_equal "ParentFoo", reloaded_parent.afield
    assert_equal 2, reloaded_parent.child_filters.length

    assert_equal ["Foo"], reloaded_parent.child_filters.child_nnn("Foo").map(&:bfield)
  end

  def test_no_param_filter
    p1 = @scope.ParentFilter.new({:afield => "Foo"})
    p2 = @scope.ParentFilter.new({:afield => "Bar"})
    p1.save
    p2.save

    no_param = @scope.ParentFilter.no_param
    assert_equal ["Foo"], no_param.map(&:afield)
  end

  def test_has_many
    @scope.Zoo.new(:name => "Foo1").save
    @scope.Zoo.new(:name => "Foo2").save
    assert_equal 2, @scope.Zoo.all.length
    all_zoo_ids = @scope.Zoo.all.map(&:id)
    v1 = @scope.ZooOwner.new({:name => "Foo", :zoo_ids => all_zoo_ids})
    v1.save

    v1_reloaded = @scope.ZooOwner.all.first
    assert_equal all_zoo_ids, v1_reloaded.zoo_ids

    url = v1.resource_location + '/' + Zoo.resource_name
    Arrest::Source.source.cheat_collection(url, v1_reloaded.zoo_ids)
    assert_equal 2,v1_reloaded.zoos.length
    assert_equal "Foo1", v1_reloaded.zoos.first.name
  end


  def test_scope_has_many
    z1 = @scope.Zoo.new(:name => "Foo1", :open => true)
    z1.save
    z2 = @scope.Zoo.new(:name => "Foo2", :open => false)
    z2.save
    z3 = @scope.Zoo.new(:name => "Foo3", :open => true)
    z3.save
    assert_equal 3, @scope.Zoo.all.length
    all_zoo_ids = [z1.id, z2.id]
    v1 = @scope.ZooOwner.new({:name => "Foo", :zoo_ids => all_zoo_ids})
    v1.save

    v1_reloaded = @scope.ZooOwner.all.first
    assert_equal all_zoo_ids, v1_reloaded.zoo_ids

    url = v1.resource_location + '/' + Zoo.resource_name
    Arrest::Source.source.cheat_collection(url, v1_reloaded.zoo_ids)
    assert_equal 2,v1_reloaded.zoos.length
    assert_equal "Foo1", v1_reloaded.zoos.first.name

    assert_equal 1, v1_reloaded.zoos.open_filter.length
    assert_equal "Foo1", v1_reloaded.zoos.open_filter.first.name
    assert_equal 3, @scope.Zoo.all.length
  end

  def test_time
    now = Time.now
    expected = now.strftime "%FT%T%z"
    t = @scope.TimeClass.new(:time => now)
    assert_equal expected, t.to_jhash[:time], "This is the expected default format"
  end

  def test_polymorphic_belongs_to
    coma = @scope.CommentableA.new()
    coma.save
    comb = @scope.CommentableB.new()
    comb.save

    c = @scope.Comment.new(:commentable_ref => { :id => coma.id, :type => coma.to_json_type.to_s})
    result = c.commentable
    assert_equal coma.id, c.commentable_ref.id
    assert_equal result.class, CommentableA

    c2 = @scope.Comment.new(:commentable_ref => { :id => comb.id, :type => comb.to_json_type.to_s})
    result2 = c2.commentable
    assert_equal comb.id, c2.commentable_ref.id
    assert_equal result2.class, CommentableB

    comd = @scope.CommentableD.new()
    comd.save

    c3 = @scope.Comment.new(:commentable_ref => { :id => comd.id, :type => comd.to_json_type.to_s})
    result = c3.commentable
    assert_equal comd.id, c3.commentable_ref.id
    assert_equal result.class, CommentableD
  end

  def test_polymorphic_belongs_to_extended
    coma = @scope.CommentableA.new()
    coma.save
    comc = @scope.CommentableC.new()
    comc.save

    c = @scope.ExtendedComment.new({ :special_commentable_ref => { :id => comc.id, :type => comc.to_json_type.to_s},
                                     :commentable_ref => { :id => coma.id, :type => coma.to_json_type.to_s }})
    assert_equal c.commentable.class, CommentableA
    assert_equal c.other_commentable.class, CommentableC

    c.save
    c_reloaded = @scope.ExtendedComment.find(c.id)
    assert_equal comc.id, c_reloaded.special_commentable_ref.id
    assert_equal CommentableC, c_reloaded.other_commentable.class
    assert_equal CommentableA, c_reloaded.commentable.class
  end

  def test_delete_all_root_resources
    d1 = @scope.DeleteMeAll.new()
    d1.save
    d2 = @scope.DeleteMeAll.new()
    d2.save

    d1_rel = @scope.DeleteMeAll.find(d1.id)
    assert_not_nil d1_rel
    d2_rel = @scope.DeleteMeAll.find(d2.id)
    assert_not_nil d2_rel
    all = @scope.DeleteMeAll.all
    assert_equal 2, all.length

    @scope.DeleteMeAll.delete_all
    all = @scope.DeleteMeAll.all
    assert all.empty?, "After deletion all entities should have been removed"
  end


  def test_equality_non_persistent
    zoo1 = @scope.Zoo.new(:name => 'zoo1')
    zoo2 = @scope.Zoo.new(:name => 'zoo2')
    zoo1.id = '1'
    zoo2.id = '1'

    assert zoo1 == zoo2
    assert_equal zoo1, zoo2
    zoo2.id = '2'
    assert zoo1 != zoo2
    assert_not_equal zoo1, zoo2
  end

  def test_equality
    zoo1 = @scope.Zoo.new(:name => 'zoo1')
    zoo2 = @scope.Zoo.new(:name => 'zoo2')

    assert zoo1.save, 'simple zoo should be saveable'
    assert zoo2.save, 'simple zoo should be saveable'

    assert_not_equal zoo1.id, zoo2.id, 'new zoos should have different ids'

    assert_not_equal zoo1,zoo2, 'objects with different ids should not be equal'

    assert_equal zoo1, zoo1, 'An object should be equal to itself'

    assert_not_equal zoo1, nil, 'Anactual object should not equal nil'

    zoo1_reloaded = @scope.Zoo.find(zoo1.id)
    assert_not_nil zoo1_reloaded

    assert zoo1 == zoo1_reloaded, "Objects of the same class with the same id should be equal"

    foo = @scope.Foo.new()
    foo.id = zoo1.id

    assert_not_equal zoo1, foo, "Objects of different classes should not be euqal, even if they have the same id"

    zoo1_reloaded.name = 'zoooooo'
    assert_equal zoo1, zoo1_reloaded, "Objects of the same class with the same id should be equal even if they differ in attributes (same as in rails)"
  end


  def test_update_attribute
    zoo1 = @scope.Zoo.new(:name => 'zoo1')
    assert zoo1.save
    zoo1.update_attributes({:name => "updated"})
    assert_equal "updated", zoo1.name

    zoo_reloaded = @scope.Zoo.find(zoo1.id)
    assert_equal "updated", zoo_reloaded.name

  end

  def test_reload
    zoo1 = @scope.Zoo.new(:name => 'zoo1')
    assert zoo1.save

    zoo2 = @scope.Zoo.find(zoo1.id)
    assert zoo2.save

    zoo1.name = "updated"
    assert zoo1.save

    assert_not_equal zoo1.name, zoo2.name

    zoo2.reload

    assert_equal zoo1.name, zoo2.name
  end

  def test_unset_property
    # just taking a class that has a not mandatory attribute
    zo = @scope.ZooOwner.new({ :name => 'meeeee' })
    assert zo.save

    zo.name = nil
    assert zo.save

    assert_nil zo.name, "Name should be unset"
  end
end
