require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}AliasHandler" do
  before(:all) { parse_file :alias_handler_001, __FILE__ }

  it "should throw alias into namespace object list" do
    P(:A).aliases[P("A#b")].should == :a
  end
  
  ['c', 'd?', '[]', '[]=', '-@', '%', '*'].each do |a|
    it "should handle the Ruby 'alias' keyword syntax for method ##{a}" do
      P('A#' + a).should be_instance_of(CodeObjects::MethodObject)
    end
  end
  
  it "should handle keywords as the alias name" do
    P('A#for').should be_instance_of(CodeObjects::MethodObject)
  end
  
  it "should allow ConstantNames to be specified as aliases" do
    P('A#ConstantName').should be_instance_of(CodeObjects::MethodObject)
  end
  
  it "should create a new method object for the alias" do
    P("A#b").should be_instance_of(CodeObjects::MethodObject)
  end
  
  it "should pull the method into the current class if it's from another one" do
    P(:B).aliases[P("B#q")].should == :x
    P(:B).aliases[P("B#r?")].should == :x
  end
  
  it "should gracefully fail to pull a method in if the original method cannot be found" do
    P(:B).aliases[P("B#s")].should == :to_s
  end
  
  it "should allow complex Ruby expressions after the alias parameters" do
    P(:B).aliases[P("B#t")].should == :inspect
  end
  
  it "should show up in #is_alias? for method" do
    P("B#t").is_alias?.should == true 
    P('B#r?').is_alias?.should == true
  end

  it "should allow operators and keywords to be specified as symbols" do
    P('B#<<').should be_instance_of(CodeObjects::MethodObject)
    P('B#for').should be_instance_of(CodeObjects::MethodObject)
  end
  
  it "should raise an UndocumentableError if only one parameter is passed" do
    undoc_error "alias_method :q"
  end
  
  it "should raise an UndocumentableError if the parameter is not a Symbol or String" do
    undoc_error "alias_method CONST, Something"
    undoc_error "alias_method variable, ClassName"
    undoc_error "alias_method variable, other_variable"
  end
end
