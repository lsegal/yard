describe YARD::Generators::Helpers::HtmlHelper do
  include YARD::Generators::Helpers::HtmlHelper
  
  it "should use #h to escape HTML" do
    h('Usage: foo "bar" <baz>').should == "Usage: foo &quot;bar&quot; &lt;baz&gt;"
  end
  
  it "should use #urlencode to encode URLs" do
    pending do
      urlencode("http://www.yahoo.com/Foo Bar/#anchor").should == "http://www.yahoo.com/Foo+Bar/#anchor"
    end
  end
  
  it "should linkify a path"
end

describe YARD::Generators::Helpers::HtmlHelper, '#url_for' do
  include YARD::Generators::Helpers::HtmlHelper
  
  def serializer; @serializer end
  def current_object; @current_object end
  
  it "should return empty string if serializer is nil" do
    stub!(:serializer).and_return nil
    stub!(:current_object).and_return Registry.root
    url_for(P("Mod::Class#meth")).should == ''
  end
  
  it "should return empty string if serializer does not implement #serialized_path" do
    stub!(:serializer).and_return Serializers::Base.new
    stub!(:current_object).and_return Registry.root
    url_for(P("Mod::Class#meth")).should == ''
  end
end