require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ModuleHandler do
  before do
    Registry.clear 
    parse_file :module_handler_001, __FILE__
  end

  it "should parse a module block" do
    Registry.at(:ModName).path.should_not == nil
    Registry.at("ModName::OtherModName").path.should_not == nil
  end
  
  it "should attach docstring" do
    Registry.at("ModName::OtherModName").docstring.should == "Docstring"
  end
end