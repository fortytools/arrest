require 'test/unit'
require 'arrest'
require 'active_model'

class PresenceOfClass < Arrest::RootResource
  attr_accessor :foo

  validates_presence_of :foo

  def initialize foo
    @foo = foo
  end
end

class PresenceOfTwo
  include ActiveModel::Validations
  attr_accessor :foo, :bar

  validates_presence_of :foo
  validates_presence_of :bar

  def initialize foo = nil, bar = nil
    @foo = foo
    @bar = bar
  end
end

class InheritedPresence < PresenceOfClass
  attr_accessor :baz

  validates_presence_of :baz

  def initialize foo = nil, baz = nil
    super foo
    @baz = baz
  end
end

class CustomVal
  include ActiveModel::Validations
  attr_accessor :foo

  validate :is_foo

  def initialize foo=nil
    @foo = foo
  end
  
  def is_foo
    if self.foo != "Foo"
      errors.add(:foo, "is not foo")
    end
  end
end

class InclusionOfClass
  include ActiveModel::Validations

  attr_accessor :foo

  validates :foo, :inclusion => { :in => ["Foo", "Bar"] }

  def initialize foo
    @foo = foo
  end
end

class ValidationsTest < Test::Unit::TestCase


  def setup
     Arrest::Source.source = nil
     #Arrest::Source.debug = true
     Arrest::Source.skip_validations = false
  end

  def test_prsnc
    o0 = PresenceOfClass.new nil
    assert o0.valid? == false, "Foo is '#{o0.foo}' -> not present and thus not valid!"

    o1 = PresenceOfClass.new "Foo"
    assert o1.valid?, "Foo is present and valid!"
  end

  def test_skip_validations
    Arrest::Source.skip_validations = true
    o0 = PresenceOfClass.new nil
    assert o0.valid? == false, "Foo is '#{o0.foo}' -> not present and thus not valid!"
    assert o0.save, "When skipping validations, in-mem-storage should work"

    Arrest::Source.skip_validations = false
  end

  def test_presence_of_two
    o = PresenceOfTwo.new 
    assert o.valid? == false, "Both missing, must not be valid"

    o = PresenceOfTwo.new "foo"
    assert o.valid? == false, "bar missing, must not be valid"

    o = PresenceOfTwo.new nil, "bar"
    assert o.valid? == false, "foo missing, must not be valid"

    o = PresenceOfTwo.new '', "bar"
    assert o.valid? == false, "foo missing, must not be valid"

    o = PresenceOfTwo.new "foo", "bar"
    assert o.valid?, "complete -> should be valid"
  end

  def test_inheritance
    o = InheritedPresence.new
    assert o.valid? == false, "Both missing, shouldnt be valid"

    o = InheritedPresence.new "Foo"
    assert o.valid? == false, "Baz missing, shouldnt be valid"

    o = InheritedPresence.new "Foo", ''
    assert o.valid? == false, "Baz missing, shouldnt be valid"

    o = InheritedPresence.new "", "Baz"
    assert o.valid? == false, "Foo missing, shouldnt be valid"

    o = InheritedPresence.new nil, "Baz"
    assert o.valid? == false, "Foo missing, shouldnt be valid"

    o = InheritedPresence.new "Foo", "Baz"
    assert o.valid? , "Nothing missing, should be valid"
  end

  def test_method_valid
    o = CustomVal.new
    assert o.valid? == false, "no foo is not valid"

    o = CustomVal.new("Bar")
    assert o.valid? == false, "Bar is not Foo thus is not valid"

    o = CustomVal.new("Foo")
    assert_equal "Foo", o.foo
    assert o.valid?, "Foo should be valid"
  end

  # ================ inclusion_of ======


  def test_inclusion_of
    invalids = [nil, '', "Baz", "foo", 3, true]

    valids = ["Foo", "Bar"]

    invalids.each do |iv|
      o = InclusionOfClass.new(iv)
      assert o.valid? == false, "#{iv} is not valid"
    end

    valids.each do |v|
      o = InclusionOfClass.new(v)
      assert o.valid?
    end
  end
end

