require File.dirname(__FILE__) + '/../spec_helper'

#described_in_docs String, '#camelcase'
#described_in_docs String, '#underscore'

describe String, '#camelcase' do
  it 'should turn HelloWorld into hello_world' do
    "HelloWorld".underscore.should == "hello_world"
  end
end

describe String, '#underscore' do
  it 'should turn hello_world into HelloWorld' do
    "hello_world".camelcase.should == "HelloWorld"
  end
end