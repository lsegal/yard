require File.dirname(__FILE__) + '/../spec_helper'

#described_in_docs String, '#camelcase'
#described_in_docs String, '#underscore'

describe String, '#underscore' do
  it 'should turn HelloWorld into hello_world' do
    "HelloWorld".underscore.should == "hello_world"
  end
  
  it "should turn Hello::World into hello/world" do
    "Hello::World".underscore.should == "hello/world"
  end
end

describe String, '#camelcase' do
  it 'should turn hello_world into HelloWorld' do
    "hello_world".camelcase.should == "HelloWorld"
  end

  it "should turn hello/world into Hello::World" do
    "Hello::World".underscore.should == "hello/world"
  end
end