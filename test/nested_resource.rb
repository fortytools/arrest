require 'test/unit'
load 'test/models.rb'

class NestedResourcesTest < Test::Unit::TestCase

  def setup
     Arrest::Source.source = nil
     #Arrest::Source.debug = true
  end

  def test_instance_test
    n = ANestedClass.new({:name => "foo"})
    assert_equal "foo", n.name
  end

end
