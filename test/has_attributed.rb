require 'arrest'
require 'test/unit'
class HasAttributesTest < Test::Unit::TestCase

  class ItHas
    include Arrest::HasAttributes

    attribute :name, String
    attribute :my_name, String
  end


  def test_empty_new
    ih = ItHas.new
    ih.name = "NAME"
    ih.my_name = "MYNAME"
    assert_equal "NAME", ih.name
    assert_equal "MYNAME", ih.my_name
  end

  def test_new
    ih = ItHas.new({:name => "NAME", :my_name => "MYNAME"})
    assert_equal "NAME", ih.name
    assert_equal "MYNAME", ih.my_name
  end

  class ItHasMore < ItHas

    attribute :my_other_name, String
  end

  def test_new_inherit
    ih = ItHasMore.new({:name => "NAME", :my_name => "MYNAME", :my_other_name => "OTHER"})
    assert_equal "NAME", ih.name
    assert_equal "MYNAME", ih.my_name
    assert_equal "OTHER", ih.my_other_name
    assert_equal 3, ih.class.all_fields.length
  end

  def test_to_json
    ih = ItHasMore.new({:name => "NAME", :my_name => "MYNAME", :my_other_name => "OTHER"})
    h = ih.to_hash
    assert_equal "NAME", h[:name]
    assert_equal "MYNAME", h[:my_name]
    assert_equal "OTHER", h[:my_other_name]

  end

  class ItHasMoreAndId < ItHasMore
    attribute :id, String
  end

  def test_to_json_with_id
    assert_equal [:name, :my_name].sort, ItHas.all_fields.map(&:name).sort
    assert_equal [:name, :my_name, :my_other_name].sort, ItHasMore.all_fields.map(&:name).sort
    assert_equal [:name, :my_name, :my_other_name, :id].sort, ItHasMoreAndId.all_fields.map(&:name).sort

    ih = ItHasMoreAndId.new({:id => 'vr23', :name => "NAME", :my_name => "MYNAME", :my_other_name => "OTHER"})
    ih.id = 'foo42'
    h = ih.to_hash
    assert_equal "NAME", h[:name]
    assert_equal "MYNAME", h[:my_name]
    assert_equal "OTHER", h[:my_other_name]
    assert_equal 'foo42', h[:id]
  end

  class GotMe < Arrest::RootResource
  end
  # for dirty tracking of attributes we need class to be a resource (which includes ActiveModel::Dirty)
  class ItHasResource < Arrest::RootResource
    attribute :name, String
    has_many :got_mes, :sub_resource => true
  end

  def test_dirty_attribute
    Arrest::Source.source = nil
    Arrest::Source.skip_validations = false

    ih = ItHasResource.new({:name => "Bla"})
    ih.save
    assert !ih.got_me_ids_changed?
    assert !ih.changed?

    ih.got_me_ids = ["huhu"]
    assert ih.got_me_ids_changed?
    assert ih.changed?
    ih.save

    assert !ih.got_me_ids_changed?
    assert !ih.changed?

    ih.got_me_ids = ["huhu"]
    assert !ih.got_me_ids_changed?
    assert !ih.changed?
  end
end

