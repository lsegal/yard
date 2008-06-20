require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Tags::DefaultFactory, "parse_types" do
  before { @f = YARD::Tags::DefaultFactory.new }
  
  def parse_types(types)
    @f.send(:parse_types, types)
  end
  
  it "should handle one type" do
    parse_types('[A]').should == [['A'], (0..2)]
  end

  it "should handle a list of types" do
    parse_types('[A, B, C]').should == [['A', 'B', 'C'], (0..8)]
  end
  
  it "should handle a complex list of types" do
    v = parse_types(' [Test, Array<String, Hash{A => B}, C>, String]')
    v.should include(["Test", "Array<String, Hash{A => B}, C>", "String"])
  end
  
  it "should handle any of the following start/end delimiting chars: (), <>, {}, []" do
    a = parse_types('[a,b,c]')
    b = parse_types('<a,b,c>')
    c = parse_types('(a,b,c)')
    d = parse_types('{a,b,c}')
    a.should == b
    b.should == c
    c.should == d
    a.should include(['a','b','c'])
  end
  
  it "should stop if a non delimiting char is found before the opening delimiter" do
    parse_types('b[x, y, z]').should be_nil
    parse_types('  ! <x>').should be_nil
  end
  
  it "should return nil if the type list is empty" do
    parse_types('[]').should be_nil
  end
end