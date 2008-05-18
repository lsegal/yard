require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::AttributeHandler do
  before { parse_file :attribute_handler_001, __FILE__ }
  
  def read_write(namespace, name, read, write)
    rname, wname = namespace.to_s+"#"+name.to_s, namespace.to_s+"#"+name.to_s+"="
    if read
      Registry.at(rname).should be_instance_of(CodeObjects::MethodObject) 
    else
      Registry.at(rname).should == nil
    end
    
    if write
      Registry.at(wname).should be_kind_of(CodeObjects::MethodObject) 
    else
      Registry.at(wname).should == nil
    end     
    
    attrs = Registry.at(namespace).attributes[name]
    attrs[:read].should == read
    attrs[:write].should == write
  end
  
  it "should parse attributes inside modules too" do
    Registry.at("A#x=").should_not == nil
  end
  
  it "should parse 'attr'" do
    read_write(:B, :a, true, true)
    read_write(:B, :a2, true, false)
    read_write(:B, "a3", true, false)
  end
  
  it "should parse 'attr_reader'" do
    read_write(:B, :b, true, false)
  end
  
  it "should parse 'attr_writer'" do
    read_write(:B, :e, false, true)
  end
  
  it "should parse 'attr_accessor'" do
    read_write(:B, :f, true, true)
  end
  
  it "should parse a list of attributes" do
    read_write(:B, :b, true, false)
    read_write(:B, :c, true, false)
    read_write(:B, :d, true, false)
  end
  
  it "should have a default docstring if one is not supplied" do
    Registry.at("B#f=").docstring.should_not be_empty
  end
  
  it "should set the correct docstring if one is supplied" do
    Registry.at("B#b").docstring.should == "Docstring"
    Registry.at("B#c").docstring.should == "Docstring"
    Registry.at("B#d").docstring.should == "Docstring"
  end
end