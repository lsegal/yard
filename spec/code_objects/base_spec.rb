require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::Base do
  before { Registry.clear }
  
  it "should return a unique instance of any registered object" do
    obj = ClassObject.new(:root, :Me)
    obj2 = ModuleObject.new(:root, :Me)
    obj.object_id.should == obj2.object_id
    
    obj3 = ModuleObject.new(obj, :Too)
    obj4 = CodeObjects::Base.new(obj3, :Hello)
    obj4.parent = obj
    
    obj5 = CodeObjects::Base.new(obj3, :hello)
    obj4.object_id.should_not == obj5.object_id
  end
  
  it "should recall the block if #new is called on an existing object" do
    o1 = ClassObject.new(:root, :Me) do |o|
      o.docstring = "DOCSTRING"
    end
    
    o2 = ClassObject.new(:root, :Me) do |o|
      o.docstring = "NOT_DOCSTRING"
    end
    
    o1.object_id.should == o2.object_id
    o1.docstring.should == "NOT_DOCSTRING"
    o2.docstring.should == "NOT_DOCSTRING"
  end
  
  it "should handle empty docstrings with #short_docstring" do
    o1 = ClassObject.new(nil, :Me) 
    o1.short_docstring.should == ""
  end
  
  it "should return the first sentence with #short_docstring" do
    o = ClassObject.new(nil, :Me) 
    o.docstring = "DOCSTRING. Another sentence"
    o.short_docstring.should == "DOCSTRING."
  end

  it "should return the first paragraph with #short_docstring" do
    o = ClassObject.new(nil, :Me)
    o.docstring = "DOCSTRING, and other stuff\n\nAnother sentence."
    o.short_docstring.should == "DOCSTRING, and other stuff."
  end
  
  it "should return proper short_docstring when docstring is changed" do
    o = ClassObject.new(:root, :Me)
    o.docstring = "DOCSTRING, and other stuff\n\nAnother sentence."
    o.short_docstring.should == "DOCSTRING, and other stuff."
    o.docstring = "DOCSTRING."
    o.short_docstring.should == "DOCSTRING."
  end
  
  it "should not double the ending period in short_docstring" do
    o = ClassObject.new(nil, :Me)
    o.docstring = "Returns a list of tags specified by +name+ or all tags if +name+ is not specified.\n\nTest"
    o.short_docstring.should == "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
    
    Parser::SourceParser.parse_string <<-eof
      ##
      # Returns a list of tags specified by +name+ or all tags if +name+ is not specified.
      #
      # @param name the tag name to return data for, or nil for all tags
      # @return [Array<Tags::Tag>] the list of tags by the specified tag name
      def tags(name = nil)
        return @tags if name.nil?
        @tags.select {|tag| tag.tag_name.to_s == name.to_s }
      end
    eof
    P('#tags').short_docstring.should == "Returns a list of tags specified by +name+ or all tags if +name+ is not specified."
  end
  
  it "should allow complex name and convert that to namespace" do
    obj = CodeObjects::Base.new(nil, "A::B")
    obj.namespace.path.should == "A"
    obj.name.should == :B
  end
  
  it "should allow namespace to be nil and not register in the Registry" do
    obj = CodeObjects::Base.new(nil, :Me)
    obj.namespace.should == nil
    Registry.at(:Me).should == nil
  end
  
  it "should allow namespace to be a NamespaceObject" do
    ns = ModuleObject.new(:root, :Name)
    obj = CodeObjects::Base.new(ns, :Me)
    obj.namespace.should == ns
  end
  
  it "should allow :root to be the shorthand namespace of `Registry.root`" do
    obj = CodeObjects::Base.new(:root, :Me)
    obj.namespace.should == Registry.root
  end
  
  
  it "should not allow any other types as namespace" do
    lambda { CodeObjects::Base.new("ROOT!", :Me) }.should raise_error(ArgumentError)
  end
  
  it "should register itself in the registry if namespace is supplied" do
    obj = ModuleObject.new(:root, :Me)
    Registry.at(:Me).should == obj
    
    obj2 = ModuleObject.new(obj, :Too)
    Registry.at(:"Me::Too").should == obj2
  end
  
  it "should set any attribute using #[]=" do
    obj = ModuleObject.new(:root, :YARD)
    obj[:some_attr] = "hello"
    obj[:some_attr].should == "hello"
  end
  
  it "#[]= should use the accessor method if available" do
    obj = CodeObjects::Base.new(:root, :YARD)
    obj[:source] = "hello"
    obj.source.should == "hello"
    obj.source = "unhello"
    obj[:source].should == "unhello"
  end
  
  it "should set attributes via attr= through method_missing" do
    obj = CodeObjects::Base.new(:root, :YARD)
    obj.something = 2
    obj.something.should == 2
    obj[:something].should == 2
  end
  
  it "should exist in the parent's #children after creation" do
    obj = ModuleObject.new(:root, :YARD)
    obj2 = MethodObject.new(obj, :testing)
    obj.children.should include(obj2)
  end
  
  it "should parse comments into tags" do
    obj = CodeObjects::Base.new(nil, :Object)
    comments = <<-eof
      @param name Hello world
        how are you?
      @param name2 
        this is a new line
      @param name3 and this
        is a new paragraph:

        right here.
    eof
    obj.send(:parse_comments, comments)
    obj.tags("param").each do |tag|
      if tag.name == "name"
        tag.text.should == "Hello world how are you?"
      elsif tag.name == "name2"
        tag.text.should == "this is a new line"
      elsif tag.name == "name3"
        tag.text.should == "and this is a new paragraph:\n\nright here."
      end
    end
  end
  
  it "should properly re-indent source starting from 0 indentation" do
    obj = CodeObjects::Base.new(nil, :test)
    obj.source = <<-eof
      def mymethod
        if x == 2 &&
            5 == 5
          3 
        else
          1
        end
      end
    eof
    obj.source.should == "def mymethod\n  if x == 2 &&\n      5 == 5\n    3 \n  else\n    1\n  end\nend"
    
    Registry.clear
    Parser::SourceParser.parse_string <<-eof
      def key?(key)
        super(key)
      end
    eof
    Registry.at('#key?').source.should == "def key?(key)\n  super(key)\nend"

    Registry.clear
    Parser::SourceParser.parse_string <<-eof
        def key?(key)
          if x == 2
            puts key
          else
            exit
          end
        end
    eof
    Registry.at('#key?').source.should == "def key?(key)\n  if x == 2\n    puts key\n  else\n    exit\n  end\nend"

  end
  
  it "should handle source for 'def x; end'" do
    Registry.clear
    Parser::SourceParser.parse_string "def x; 2 end"
    Registry.at('#x').source.should == "def x; 2 end"
  end
end