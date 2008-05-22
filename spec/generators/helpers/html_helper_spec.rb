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