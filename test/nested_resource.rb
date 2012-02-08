require 'test/unit'
load 'test/models.rb'

class NestedResourcesTest < Test::Unit::TestCase

  def setup
     Arrest::Source.source = nil
     @scope = Arrest::ScopedRoot.new
     #Arrest::Source.debug = true
  end

  def test_instance_test
    n = ANestedClass.new(nil, {:name => "foo", :underscore_name => "Bar"})
    assert_equal "foo", n.name
    assert_equal "Bar", n.underscore_name
  end

  def test_from_hash
    input = {
      :parent_name => 'parent',
      :bool => false,
      :nested_object => {
        :name => 'iamnested',
        :underscore_name => 'foo',
        :bool => true
      }
    }

    actual = @scope.WithNested.new(input)
    assert_equal 'parent', actual.parent_name
    assert_equal false, actual.bool
    assert actual.respond_to? :nested_object, "The parent object should have an accessor for the nested object"
    assert_equal 'iamnested', actual.nested_object.name
    assert_equal true, actual.nested_object.bool
  end

  def test_to_hash
    input = {
      :parent_name => 'parent',
      :bool => false,
      :nested_object => {
        :name => 'iamnested',
        :underscore_name => 'foo',
        :bool => true
      }
    }

    actual = @scope.WithNested.new(input)

    assert_equal_hashes input, actual.to_hash

  end

  def test_many_to_hash
    input = {
      :parent_name => 'parent',
      :bool => false,
      :nested_objects => [
        {
        :name => 'iamnested_one',
        :bool => true
        },{
        :name => 'iamnested_two',
        :bool => false
        }
      ]
    }

    actual = @scope.WithManyNested.new(input)

    assert_equal_hashes input, actual.to_hash

  end

  def test_belongs_to_to_hash
    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    input = {
      :parent_name => 'parent',
      :bool => false,
      :nested_object => {
        :name => 'iamnested',
        :bool => true,
        :zoo_id => new_zoo.id
      }
    }

    actual = @scope.WithNestedBelongingTo.new(input)

    assert_equal_hashes input, actual.to_hash

    zoo = actual.nested_object.zoo
    assert_equal "Foo", zoo.name

  end

  def test_custom_belongs_to

    new_zoo = @scope.Zoo.new({:name => "Foo"})
    new_zoo.save

    c = @scope.CustomNamedBelongsTo.new({:name => 'Bar', :schinken => new_zoo.id, :batzen => new_zoo.id})

    c.save
    assert_not_nil c.id, "Persisted object should have id"
    assert_equal  "Foo", c.zoo_thing.name
    assert_equal  "Foo", c.zoo.name


    assert_not_nil c.id, "Persisted zoo should have id"
    c_reloaded = @scope.CustomNamedBelongsTo.all.first
    assert_equal  "Foo", c_reloaded.zoo_thing.name
    assert_equal  "Foo", c_reloaded.zoo.name

  end

  def assert_equal_hashes expected, actual
    assert_equal_hashes_ expected, actual, ''
  end

  def assert_equal_hashes_ expected, actual, prefix
    more_expected_keys = (expected.keys - actual.keys).map{|k| prefix + k.to_s }
    assert more_expected_keys.empty?, "Actual misses keys: #{more_expected_keys}"
    more_actual_keys = (actual.keys - expected.keys).map{|k| prefix + k.to_s }
    assert more_expected_keys.empty?, "Actual has more keys: #{more_actual_keys}"

    expected.each_pair do |ek, ev|
      av = actual[ek]
      if ev != nil && ev.is_a?(Hash)
        assert_equal_hashes_ ev, av, "#{prefix}."
      end
      assert_equal ev, av
    end
  end


end
