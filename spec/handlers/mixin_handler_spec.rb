require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}MixinHandler" do
  before(:all) { parse_file :mixin_handler_001, __FILE__ }

  it "should handle includes from classes or modules" do
    Registry.at(:X).instance_mixins.should include(P(:A))
    Registry.at(:Y).instance_mixins.should include(P(:A))
  end

  it "should handle includes in class << self" do
    Registry.at(:Y).class_mixins.should include(P(:A))
  end

  it "should handle includes for modules that don't yet exist" do
    Registry.at(:X).instance_mixins.should include(P(nil, :NOTEXIST))
  end

  it "should set the type of non-existing modules to :module" do
    o = Registry.at(:X).instance_mixins.find {|o| o.name == :NOTEXIST }
    expect(o.type).to eq :module
  end

  it "should handle includes with multiple parameters" do
    Registry.at(:X).should_not be_nil
  end

  it "should handle complex include statements" do
    P(:Y).instance_mixins.should include(P('B::C'))
    P(:Y).instance_mixins.should include(P(:B))
  end

  it "should treat a mixed in Constant by taking its value as the real object name" do
    P(:Y).instance_mixins.should include(Registry.at('B::D'))
  end

  it "should add includes in the correct order when include is given multiple arguments" do
    expect(P(:Z).instance_mixins).to eq [P(:A), P(:B)]
  end

  it "should avoid including self for unresolved mixins of the same name" do
    expect(P("ABC::DEF::FOO").mixins).to eq [P("ABC::FOO")]
    expect(P("ABC::DEF::BAR").mixins).to eq [P("ABC::BAR")]
  end

  it "should raise undocumentable error if argument is variable" do
    undoc_error "module X; include invalid; end"
    expect(Registry.at('X').mixins).to eq []
  end

  it "should parse all other arguments before erroring out on undocumentable error" do
    undoc_error "module X; include invalid, Y; end"
    expect(Registry.at('X').mixins).to eq [P('Y')]
  end
end
