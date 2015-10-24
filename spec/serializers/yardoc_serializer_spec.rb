require File.dirname(__FILE__) + "/spec_helper"

instance_eval do
  class YARD::Serializers::YardocSerializer
    public :dump
    public :internal_dump
  end
end

describe YARD::Serializers::YardocSerializer do
  before do
    @serializer = YARD::Serializers::YardocSerializer.new('.yardoc')

    Registry.clear
    @foo = CodeObjects::ClassObject.new(:root, :Foo)
    @bar = CodeObjects::MethodObject.new(@foo, :bar)
  end

  describe "#dump" do
    it "maintains object equality when loading a dumped object" do
      newfoo = @serializer.internal_dump(@foo)
      expect(newfoo).to equal(@foo)
      expect(newfoo).to eq @foo
      expect(@foo).to equal(newfoo)
      expect(@foo).to eq newfoo
      expect(newfoo.hash).to eq @foo.hash
    end

    it "maintains hash key equality when loading a dumped object" do
      newfoo = @serializer.internal_dump(@foo)
      expect({@foo => 1}).to have_key(newfoo)
      expect({newfoo => 1}).to have_key(@foo)
    end
  end

  describe "#serialize" do
    it "accepts a hash of codeobjects (and write to root)" do
      data = {:root => Registry.root}
      marshaldata = Marshal.dump(data)
      filemock = double(:file)
      expect(filemock).to receive(:write).with(marshaldata)
      expect(File).to receive(:open!).with('.yardoc/objects/root.dat', 'wb').and_yield(filemock)
      @serializer.serialize(data)
    end
  end
end