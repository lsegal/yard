describe YARD::Generators::Helpers::HtmlHelper, "basic HTML methods" do
  include YARD::Generators::Helpers::HtmlHelper
  
  it "should use #h to escape HTML" do
    h('Usage: foo "bar" <baz>').should == "Usage: foo &quot;bar&quot; &lt;baz&gt;"
  end
  
  it "should use #fix_typewriter to convert +text+ to <tt>text</tt>" do
    fix_typewriter("Some +typewriter text+.").should == "Some <tt>typewriter text</tt>."
    fix_typewriter("Not +typewriter text.").should == "Not +typewriter text."
    fix_typewriter("Alternating +type writer+ text +here+.").should == "Alternating <tt>type writer</tt> text <tt>here</tt>."
    fix_typewriter("No ++problem.").should == "No ++problem."
    fix_typewriter("Math + stuff +is ok+").should == "Math + stuff <tt>is ok</tt>"
  end
end

describe YARD::Generators::Helpers::HtmlHelper, "#link_object" do
  include YARD::Generators::Helpers::HtmlHelper
  
  it "should return the object path if there's no serializer and no title" do
    stub!(:serializer).and_return nil
    link_object(CodeObjects::NamespaceObject.new(nil, :YARD)).should == "YARD"
  end
  
  it "should return the title if there's a title but no serializer" do
    stub!(:serializer).and_return nil
    link_object(CodeObjects::NamespaceObject.new(nil, :YARD), 'title').should == "title"
  end
end

describe YARD::Generators::Helpers::HtmlHelper, '#url_for' do
  include YARD::Generators::Helpers::HtmlHelper
  
  before { Registry.clear }
  
  it "should return nil if serializer is nil" do
    stub!(:serializer).and_return nil
    stub!(:current_object).and_return Registry.root
    url_for(P("Mod::Class#meth")).should be_nil
  end
  
  it "should return nil if serializer does not implement #serialized_path" do
    stub!(:serializer).and_return Serializers::Base.new
    stub!(:current_object).and_return Registry.root
    url_for(P("Mod::Class#meth")).should be_nil
  end
  
  it "should link to a path/file for a namespace object" do
    stub!(:serializer).and_return Serializers::FileSystemSerializer.new
    stub!(:current_object).and_return Registry.root
    
    yard = CodeObjects::ModuleObject.new(:root, :YARD)
    url_for(yard).should == 'YARD.html'
  end
  
  it "should link to the object's namespace path/file and use the object as the anchor" do
    stub!(:serializer).and_return Serializers::FileSystemSerializer.new
    stub!(:current_object).and_return Registry.root
    
    yard = CodeObjects::ModuleObject.new(:root, :YARD)
    meth = CodeObjects::MethodObject.new(yard, :meth)
    url_for(meth).should == 'YARD.html#meth-instance_method'
  end
end