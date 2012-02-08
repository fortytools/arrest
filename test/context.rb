require 'test/unit'
require 'arrest'
class ContextTest < Test::Unit::TestCase

  def setup
    Arrest::Source.source = nil
  end

  class Facility < Arrest::RootResource
  end
  

  class HeaderDeco
    def self.headers
      puts "MAAAAAHH"
      {}
    end
  end

  def test_context
    context = Arrest::RequestContext.new()
    context.header_decorator = HeaderDeco
    scope = Arrest::ScopedRoot.new(context)
    assert_not_nil scope.Facility
    assert_not_nil scope.Facility.all

    f0 = scope.Facility.new(:name => 'Foo')
    assert f0.save

    f1 = scope.Facility.all.first
    f2 = scope.Facility.find(f1.id)

  end
end

