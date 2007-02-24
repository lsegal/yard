require "test/unit"

require File.dirname(__FILE__) + "/../lib/namespace"

class TestNamespace < Test::Unit::TestCase
  def test_root_namespace
    assert :root, YARD::Namespace.root.type
    assert :root, YARD::Namespace.at('').type
  end
end