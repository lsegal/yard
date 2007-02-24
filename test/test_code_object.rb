require "test/unit"
require File.dirname(__FILE__) + '/../lib/code_object'

class TestCodeObject < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/fixtures/'
  
  def setup
    @doc = YARD::CodeObject.new('node', 'module') do |obj|
      obj.attach_docstring read_fixture('docstring.txt')
    end
  end
  
  def test_return
    @doc = YARD::CodeObject.new('node', 'method') do |obj|
      obj.attach_docstring read_fixture('docstring2.txt')
    end
    assert @doc.has_tag?("return")
  end
  
  def test_source
    assert_equal 'node', @doc.name
    assert_equal '#node', @doc.path
  end
  
  def test_docstring
    assert_no_match /@param/, @doc.docstring
  end
  
  def test_tags
    assert_equal 3, @doc.tags("param").size
  end
  
  def test_has_tag
    assert @doc.has_tag?("deprecated")
    assert !@doc.has_tag?("notdefined")
  end
  
  def test_tag
    assert_equal "Loren Segal", @doc.tag("author").text
  end
  
  def test_tag_definition_on_multiple_lines
    assert_equal "it really will return anything it wants.", @doc.tag("return").text
  end
  
  def test_typed_tag
    assert 2, @doc.tags("param").last.types.size
    assert_equal ["String", "Array<String>"], @doc.tags("param").last.types
    assert_equal "String", @doc.tags("param")[1].type
    assert_equal [], @doc.tag("param").types
  end
  
  def test_named_tag
    assert_equal "normal", @doc.tags("param")[0].name
    assert_equal "obj", @doc.tags("param")[1].name
    assert_equal "obj2", @doc.tags("param")[2].name
    
    assert_equal "IOError", @doc.tag("raise").name
    assert_match "if things go wrong", @doc.tag("raise").text
  end
  
  protected
    def read_fixture(file)
      IO.read(File.join(FIXTURES_PATH, file))
    end
end