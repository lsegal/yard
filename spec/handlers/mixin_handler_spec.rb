require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}MixinHandler" do
  before { parse_file :mixin_handler_001, __FILE__ }
  
  it "should handle includes from classes or modules" do
    Registry.at(:X).mixins.should include(P(:A))
    Registry.at(:Y).mixins.should include(P(:A))
  end
  
  it "should handle includes for complex namespaces" do
  end
  
  it "should handle includes for modules that don't yet exist" do
    Registry.at(:X).mixins.should include(P(nil, :NOTEXIST))
  end
  
  it "should set the type of non-existing modules to :module" do
    P(:NOTEXIST).type.should == :module
  end
  
  it "should handle includes with multiple parameters" do
    Registry.at(:X)
  end
  
  it "should handle complex include statements" do
    P(:Y).mixins.should include(P('B::C'))
    P(:Y).mixins.should include(P(:B))
  end
  
  it "should treat a mixed in Constant by taking its value as the real object name" do
    P(:Y).mixins.should include(Registry.at('B::D'))
  end
end