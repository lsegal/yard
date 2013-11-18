require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Templates::Helpers::BaseHelper do
  include YARD::Templates::Helpers::BaseHelper

  describe '#run_verifier' do
    it "should run verifier proc against list if provided" do
      mock = Verifier.new
      expect(mock).to receive(:call).with(1)
      expect(mock).to receive(:call).with(2)
      expect(mock).to receive(:call).with(3)
      should_receive(:options).at_least(1).times.and_return(Options.new.update(:verifier => mock))
      run_verifier [1, 2, 3]
    end

    it "should prune list if lambda returns false and only false" do
      mock = Verifier.new
      should_receive(:options).at_least(1).times.and_return(Options.new.update(:verifier => mock))
      expect(mock).to receive(:call).with(1).and_return(false)
      expect(mock).to receive(:call).with(2).and_return(true)
      expect(mock).to receive(:call).with(3).and_return(nil)
      expect(mock).to receive(:call).with(4).and_return("value")
      expect(run_verifier([1, 2, 3, 4])).to eq [2, 3, 4]
    end

    it "should return list if no verifier exists" do
      should_receive(:options).at_least(1).times.and_return(Options.new)
      expect(run_verifier([1, 2, 3])).to eq [1, 2, 3]
    end
  end

  describe '#h' do
    it "should return just the text" do
      expect(h("hello world")).to eq "hello world"
      expect(h(nil)).to eq nil
    end
  end

  describe '#link_object' do
    it "should return the title if provided" do
      expect(link_object(1, "title")).to eq "title"
      expect(link_object(Registry.root, "title")).to eq "title"
    end

    it "should return a path if argument is a Proxy or object" do
      expect(link_object(Registry.root)).to eq "Top Level Namespace"
      expect(link_object(P("Array"))).to eq "Array"
    end

    it "should should return path of Proxified object if argument is a String or Symbol" do
      expect(link_object("Array")).to eq "Array"
      expect(link_object(:"A::B")).to eq "A::B"
    end

    it "should return the argument if not an object, proxy, String or Symbol" do
      expect(link_object(1)).to eq 1
    end
  end

  describe '#link_url' do
    it "should return the URL" do
      expect(link_url("http://url")).to eq "http://url"
    end
  end

  describe '#linkify' do
    before do
      stub!(:object).and_return(Registry.root)
    end

    it "should call #link_url for mailto: links" do
      should_receive(:link_url)
      linkify("mailto:steve@example.com")
    end

    it "should call #link_url for URL schemes (http://)" do
      should_receive(:link_url)
      linkify("http://example.com")
    end

    it "should call #link_file for file: links" do
      should_receive(:link_file).with('Filename', nil, 'anchor')
      linkify("file:Filename#anchor")
    end

    it "should pass off to #link_object if argument is an object" do
      obj = CodeObjects::NamespaceObject.new(nil, :YARD)
      should_receive(:link_object).with(obj)
      linkify obj
    end

    it "should return empty string and warn if object does not exist" do
      expect(log).to receive(:warn).with(/Cannot find object .* for inclusion/)
      expect(linkify('include:NotExist')).to eq ''
    end

    it "should pass off to #link_url if argument is recognized as a URL" do
      url = "http://yardoc.org/"
      should_receive(:link_url).with(url, nil, {:target => '_parent'})
      linkify url
    end

    it "should call #link_include_object for include:ObjectName" do
      obj = CodeObjects::NamespaceObject.new(:root, :Foo)
      should_receive(:link_include_object).with(obj)
      linkify 'include:Foo'
    end

    it "should call #link_include_file for include:file:path/to/file" do
      expect(File).to receive(:file?).with('path/to/file').and_return(true)
      expect(File).to receive(:read).with('path/to/file').and_return('FOO')
      expect(linkify('include:file:path/to/file')).to eq 'FOO'
    end

    it "should not allow include:file for path above pwd" do
      expect(log).to receive(:warn).with("Cannot include file from path `a/b/../../../../file'")
      expect(linkify('include:file:a/b/../../../../file')).to eq ''
    end

    it "should warn if include:file:path does not exist" do
      expect(log).to receive(:warn).with(/Cannot find file .+ for inclusion/)
      expect(linkify('include:file:notexist')).to eq ''
    end
  end

  describe '#format_types' do
    it "should return the list of types separated by commas surrounded by brackets" do
      expect(format_types(['a', 'b', 'c'])).to eq '(a, b, c)'
    end

    it "should return the list of types without brackets if brackets=false" do
      expect(format_types(['a', 'b', 'c'], false)).to eq 'a, b, c'
    end

    it "should should return an empty string if list is empty or nil" do
      expect(format_types(nil)).to eq ""
      expect(format_types([])).to eq ""
    end
  end

  describe '#format_object_type' do
    it "should return Exception if type is Exception" do
      obj = mock(:object)
      obj.stub!(:is_a?).with(YARD::CodeObjects::ClassObject).and_return(true)
      obj.stub!(:is_exception?).and_return(true)
      expect(format_object_type(obj)).to eq "Exception"
    end

    it "should return Class if type is Class" do
      obj = mock(:object)
      obj.stub!(:is_a?).with(YARD::CodeObjects::ClassObject).and_return(true)
      obj.stub!(:is_exception?).and_return(false)
      expect(format_object_type(obj)).to eq "Class"
    end

    it "should return object type in other cases" do
      obj = mock(:object)
      obj.stub!(:type).and_return("value")
      expect(format_object_type(obj)).to eq "Value"
    end
  end

  describe '#format_object_title' do
    it "should return Top Level Namespace for root object" do
      expect(format_object_title(Registry.root)).to eq "Top Level Namespace"
    end

    it "should return 'type: title' in other cases" do
      obj = mock(:object)
      obj.stub!(:type).and_return(:class)
      obj.stub!(:title).and_return("A::B::C")
      expect(format_object_title(obj)).to eq "Class: A::B::C"
    end
  end
end
