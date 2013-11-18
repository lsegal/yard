require File.dirname(__FILE__) + '/../spec_helper'

describe Array do
  describe '#place' do
    it "should create an Insertion object" do
      expect([].place('x')).to be_kind_of(Insertion)
    end

    it "should allow multiple objects to be placed" do
      expect([1, 2].place('x', 'y', 'z').before(2)).to eq [1, 'x', 'y', 'z', 2]
    end
  end
end

