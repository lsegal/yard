require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::MacroObject do
  before do 
    Registry.clear 
  end
  
  describe '.create' do
    def create(*args) MacroObject.create(*args) end

    it "should create an object" do
      create('foo', '')
      obj = Registry.at('.macro.foo')
      obj.should_not be_nil
    end
    
    it "should use identity map" do
      obj1 = create('foo', '')
      obj2 = create('foo', '')
      obj1.object_id.should == obj2.object_id
    end
    
    it "should allow specifying of macro data" do
      obj = create('foo', 'MACRODATA')
      obj.macro_data.should == 'MACRODATA'
    end
    
    it "should attach if a method object is provided" do
      obj = create('foo', 'MACRODATA', P('Foo.property'))
      obj.method_object.should == P('Foo.property')
      obj.should be_attached
    end
  end
  
  describe '.find' do
    before { MacroObject.create('foo', 'DATA') }
    
    it "should search for an object by name" do
      MacroObject.find('foo').macro_data.should == 'DATA'
    end
    
    it "should accept Symbol" do
      MacroObject.find(:foo).macro_data.should == 'DATA'
    end
  end
end
