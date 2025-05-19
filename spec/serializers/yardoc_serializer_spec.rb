# frozen_string_literal: true
require "#{File.dirname(__FILE__)}/spec_helper"

instance_eval do
  class YARD::Serializers::YardocSerializer
    public :dump
    public :internal_dump
  end
end

RSpec.describe YARD::Serializers::YardocSerializer do
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
      expect(@foo => 1).to have_key(newfoo)
      expect(newfoo => 1).to have_key(@foo)
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

  describe "#serialized_path" do
    it "handles String path name" do
      path = @serializer.serialized_path('Path::To#object')
      expect(path).to eq('objects/Path/To/object_i.dat')
    end

    it "handles special encoding characters" do
      path = @serializer.serialized_path('object$')
      expect(path).to eq('objects/object_24.dat')
    end
  end

  describe "#lock_for_writing" do
    it "creates a lock file during writing and cleans up" do
      expect(FileUtils).to receive(:touch).with(@serializer.processing_path)
      expect(File).to receive(:exist?).with(@serializer.processing_path).and_return(true)
      expect(FileUtils).to receive(:rm_f).with(@serializer.processing_path)
      @serializer.lock_for_writing do
        expect(@serializer).to be_locked_for_writing
      end
    end
  end

  describe "#complete?" do
    it "returns false if complete file does not exist" do
      allow(File).to receive(:exist?).with(@serializer.complete_lock_path).and_return(false)
      allow(File).to receive(:exist?).with(@serializer.processing_path).and_return(false)
      expect(@serializer.complete?).to eq false
    end

    it "returns false if processing file exists" do
      allow(File).to receive(:exist?).with(@serializer.complete_lock_path).and_return(true)
      allow(File).to receive(:exist?).with(@serializer.processing_path).and_return(true)
      expect(@serializer.complete?).to eq false
    end

    it "returns true if complete file exists with no processing file" do
      allow(File).to receive(:exist?).with(@serializer.complete_lock_path).and_return(true)
      allow(File).to receive(:exist?).with(@serializer.processing_path).and_return(false)
      expect(@serializer.complete?).to eq true
    end
  end
end
