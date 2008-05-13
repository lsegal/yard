require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::MixinHandler do
  before { parse_file :mixin_handler_001, __FILE__ }
  
  it "should handle includes from classes or modules" do
    Registry.at(:X).mixins.should include(P(nil, :A))
    Registry.at(:Y).mixins.should include(P(nil, :A))
  end
  
  it "should handle includes for complex namespaces" do
  end
  
  it "should handle includes for modules that don't yet exist" do
    Registry.at(:X).mixins.should include(P(nil, :NOTEXIST))
  end
  
  it "should handle includes with multiple parameters" do
    Registry.at(:X)
  end
end