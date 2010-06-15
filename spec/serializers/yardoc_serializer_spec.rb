require File.dirname(__FILE__) + "/spec_helper"

instance_eval do
  class YARD::Serializers::YardocSerializer
    public :dump
    public :internal_dump
  end
end

describe YARD::Serializers::YardocSerializer do
  describe '#dump' do
    before do
      @serializer = YARD::Serializers::YardocSerializer.new('.yardoc')

      Registry.clear
      @foo = CodeObjects::ClassObject.new(:root, :Foo)
      @bar = CodeObjects::MethodObject.new(@foo, :bar)
    end

    it "should maintain object equality when loading a dumped object" do
      newfoo = @serializer.internal_dump(@foo)
      newfoo.should equal(@foo)
      newfoo.should == @foo
      @foo.should equal(newfoo)
      @foo.should == newfoo
      newfoo.hash.should == @foo.hash
    end
    
    it "should maintain hash key equality when loading a dumped object" do
      newfoo = @serializer.internal_dump(@foo)
      {@foo => 1}.should have_key(newfoo)
      {newfoo => 1}.should have_key(@foo)
    end
  end
end