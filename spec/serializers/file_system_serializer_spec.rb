require File.join(File.dirname(__FILE__), "spec_helper")

require 'stringio'

describe YARD::Serializers::FileSystemSerializer do
  before do
    FileUtils.stub!(:mkdir_p)
    File.stub!(:open)
  end

  describe '#basepath' do
    it "should default the base path to the 'doc/'" do
      obj = Serializers::FileSystemSerializer.new
      expect(obj.basepath).to eq 'doc'
    end
  end

  describe '#extension' do
    it "should default the file extension to .html" do
      obj = Serializers::FileSystemSerializer.new
      expect(obj.extension).to eq "html"
    end
  end

  describe '#serialized_path' do
    it "should allow no extension to be used" do
      obj = Serializers::FileSystemSerializer.new :extension => nil
      yard = CodeObjects::ClassObject.new(nil, :FooBar)
      expect(obj.serialized_path(yard)).to eq 'FooBar'
    end

    it "should serialize to top-level-namespace for root" do
      obj = Serializers::FileSystemSerializer.new :extension => nil
      expect(obj.serialized_path(Registry.root)).to eq "top-level-namespace"
    end

    it "should return serialized_path for a String" do
      s = Serializers::FileSystemSerializer.new(:basepath => 'foo', :extension => 'txt')
      expect(s.serialized_path('test.txt')).to eq 'test.txt'
    end

    it "should remove special chars from path" do
      m = CodeObjects::MethodObject.new(nil, 'a')
      s = Serializers::FileSystemSerializer.new

      { :/ => '_2F_i.html',
        :gsub! => 'gsub_21_i.html',
        :ask? => 'ask_3F_i.html',
        :=== => '_3D_3D_3D_i.html',
        :+ => '_2B_i.html',
        :- => '-_i.html',
        :[]= => '_5B_5D_3D_i.html',
        :<< => '_3C_3C_i.html',
        :>= => '_3E_3D_i.html',
        :` => '_60_i.html',
        :& => '_26_i.html',
        :* => '_2A_i.html',
        :| => '_7C_i.html',
        :/ => '_2F_i.html',
        :=~ => '_3D_7E_i.html'
      }.each do |meth, value|
        m.stub!(:name).and_return(meth)
        expect(s.serialized_path(m)).to eq value
      end
    end

    it "should handle ExtraFileObject's" do
      s = Serializers::FileSystemSerializer.new
      e = CodeObjects::ExtraFileObject.new('filename.txt', '')
      expect(s.serialized_path(e)).to eq 'file.filename.html'
    end

    it "should differentiate instance and class methods from serialized path" do
      s = Serializers::FileSystemSerializer.new
      m1 = CodeObjects::MethodObject.new(nil, 'meth')
      m2 = CodeObjects::MethodObject.new(nil, 'meth', :class)
      expect(s.serialized_path(m1)).to_not eq s.serialized_path(m2)
    end

    it "should serialize path from overload tag" do
      YARD.parse_string <<-'eof'
        class Foo
          # @overload bar
          def bar; end
        end
      eof

      serializer = Serializers::FileSystemSerializer.new
      object = Registry.at('Foo#bar').tag(:overload)
      expect(serializer.serialized_path(object)).to eq "Foo/bar_i.html"
    end
  end

  describe '#serialize' do
    it "should serialize to the correct path" do
      yard = CodeObjects::ClassObject.new(nil, :FooBar)
      meth = CodeObjects::MethodObject.new(yard, :baz, :class)
      meth2 = CodeObjects::MethodObject.new(yard, :baz)

      { 'foo/FooBar/baz_c.txt' => meth,
        'foo/FooBar/baz_i.txt' => meth2,
        'foo/FooBar.txt' => yard }.each do |path, obj|
        io = StringIO.new
        expect(File).to receive(:open).with(path, 'wb').and_yield(io)
        expect(io).to receive(:write).with("data")

        s = Serializers::FileSystemSerializer.new(:basepath => 'foo', :extension => 'txt')
        s.serialize(obj, "data")
      end
    end

    it "should guarantee the directory exists" do
      o1 = CodeObjects::ClassObject.new(nil, :Really)
      o2 = CodeObjects::ClassObject.new(o1, :Long)
      o3 = CodeObjects::ClassObject.new(o2, :PathName)
      obj = CodeObjects::MethodObject.new(o3, :foo)

      expect(FileUtils).to receive(:mkdir_p).once.with('doc/Really/Long/PathName')

      s = Serializers::FileSystemSerializer.new
      s.serialize(obj, "data")
    end
  end
end
