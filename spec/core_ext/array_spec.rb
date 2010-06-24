require File.dirname(__FILE__) + '/../spec_helper'

describe Array do
  describe '#place' do
    it "should create an Insertion object" do
      [].place('x').should be_kind_of(Insertion)
    end
    
    it "should allow multiple objects to be placed" do
      [1, 2].place('x', 'y', 'z').before(2).should == [1, 'x', 'y', 'z', 2]
    end
  end
end

describe Insertion do
  describe '#before' do
    it "should place an object before another" do
      [1, 2].place(3).before(2).should == [1, 3, 2]
      [1, 2].place(3).before(1).should == [3, 1, 2]
      [1, [4], 2].place(3).before(2).should == [1, [4], 3, 2]
    end
  end
  
  describe '#after' do
    it "should place an object after another" do
      [1, 2].place(3).after(2).should == [1, 2, 3]
    end

    it "should place an object after another and its subsections" do
      [1, [2]].place(3).after(1).should == [1, [2], 3]
    end

    it "should not not ignore subsections if ignore_subections=false" do
      [1, [2]].place(3).after(1, false).should == [1, 3, [2]]
    end
    
    it "should place an array after an object" do
      [1, 2, 3].place([4]).after(1).should == [1, [4], 2, 3]
    end
  end
end
