require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Options do
  class FooOptions < YARD::Options
    attr_accessor :foo
    def initialize; self.foo = "abc" end
  end
  
  describe '.default_attr' do
    it "should allow default attributes to be defined with symbols" do
      class DefaultOptions1 < YARD::Options
        default_attr :foo, 'HELLO'
      end
      DefaultOptions1.new.foo.should == 'HELLO'
    end
    
    it "should call lambda if value is a Proc" do
      class DefaultOptions2 < YARD::Options
        default_attr :foo, lambda { 100 }
      end
      DefaultOptions2.new.foo.should == 100
    end
  end
  
  describe '#[]' do
    it "should handle getting option values using hash syntax" do
      FooOptions.new[:foo].should == "abc"
    end
  end
  
  describe '#[]=' do
    it "should handle setting options using hash syntax" do
      o = FooOptions.new
      o[:foo] = "xyz"
      o[:foo].should == "xyz"
    end
  end
  
  describe '#update' do
    it "should allow updating of options" do
      FooOptions.new.update(:foo => "xyz").foo.should == "xyz"
    end
    
    it "should ignore keys with no setter" do
      o = FooOptions.new
      o.update(:bar => "xyz")
      o.to_hash.should == {:foo => "abc"}
    end
  end
  
  describe '#merge' do
    it "should update a new object" do
      o = FooOptions.new
      o.merge(:foo => "xyz").object_id.should_not == o.object_id
      o.merge(:foo => "xyz").to_hash.should == {:foo => "xyz"}
    end
  end
  
  describe '#to_hash' do
    it "should convert all instance variables and symbolized keys" do
      class ToHashOptions1 < YARD::Options
        attr_accessor :foo, :bar, :baz
        def initialize; @foo = 1; @bar = 2; @baz = "hello" end
      end
      o = ToHashOptions1.new
      hash = o.to_hash
      hash.keys.should include(:foo, :bar, :baz)
      hash[:foo].should == 1
      hash[:bar].should == 2
      hash[:baz].should == "hello"
    end
    
    it "should use accessor when converting values to hash" do
      class ToHashOptions2 < YARD::Options
        def initialize; @foo = 1 end
        def foo; "HELLO#{@foo}" end
      end
      o = ToHashOptions2.new
      o.to_hash.should == {:foo => "HELLO1"}
    end
    
    it "should ignore ivars with no accessor" do
      class ToHashOptions3 < YARD::Options
        attr_accessor :foo
        def initialize; @foo = 1; @bar = "IGNORE" end
      end
      o = ToHashOptions3.new
      o.to_hash.should == {:foo => 1}
    end
  end
  
  describe '#tap' do
    it "should support #tap(&block) (even in 1.8.6)" do
      o = FooOptions.new.tap {|o| o.foo = :BAR }
      o.to_hash.should == {:foo => :BAR}
    end
  end
end
