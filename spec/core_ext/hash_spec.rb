require File.dirname(__FILE__) + '/../spec_helper'

describe Hash do
  describe '.[]' do
    it "should accept an Array argument (Ruby 1.8.6 and older)" do
      list = [['foo', 'bar'], ['foo2', 'bar2']]
      expect(Hash[list]).to eq ({ 'foo' => 'bar', 'foo2' => 'bar2'} )
    end

    it "should accept an array as a key" do
      expect(Hash[['a', 'b'], 1]).to eq ({ ['a', 'b'] => 1} )
    end
  end
end