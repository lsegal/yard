# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}MixinHandler" do
  before(:all) { parse_file :mixin_handler_001, __FILE__ }

  it "handles includes from classes or modules" do
    expect(Registry.at(:X).instance_mixins).to include(P(:A))
    expect(Registry.at(:Y).instance_mixins).to include(P(:A))
    expect(Registry.at(:Y).instance_mixins).to include(P('B::D')) unless LEGACY_PARSER
  end

  it "handles includes in class << self" do
    expect(Registry.at(:Y).class_mixins).to include(P(:A))
  end

  it "handles includes for modules that don't yet exist" do
    expect(Registry.at(:X).instance_mixins).to include(P(nil, :NOTEXIST))
  end

  it "sets the type of non-existing modules to :module" do
    o = Registry.at(:X).instance_mixins.find {|obj| obj.name == :NOTEXIST }
    expect(o.type).to eq :module
  end

  it "handles includes with multiple parameters" do
    expect(Registry.at(:X)).not_to be nil
  end

  it "handles complex include statements" do
    expect(P(:Y).instance_mixins).to include(P('B::C'))
    expect(P(:Y).instance_mixins).to include(P(:B))
  end

  it "treats a mixed in Constant by taking its value as the real object name" do
    expect(P(:Y).instance_mixins).to include(Registry.at('B::D'))
  end

  it "adds includes in the correct order when include is given multiple arguments" do
    expect(P(:Z).instance_mixins).to eq [P(:A), P(:B)]
  end

  it "avoids including self for unresolved mixins of the same name" do
    expect(P("ABC::DEF::FOO").mixins).to eq [P("ABC::FOO")]
    expect(P("ABC::DEF::BAR").mixins).to eq [P("ABC::BAR")]
  end

  it "raises undocumentable error if argument is variable" do
    undoc_error "module X; include invalid; end"
    expect(Registry.at('X').mixins).to eq []
  end

  it "parses all other arguments before erroring out on undocumentable error" do
    undoc_error "module X; include invalid, Y; end"
    expect(Registry.at('X').mixins).to eq [P('Y')]
  end

  it "adds mixins from include calls to constants" do
    expect(P('FromConstant').instance_mixins).to eq [P('A')]
  end

  it "can mixin a const by complex path" do
    YARD.parse_string <<-eof
      class A1; class B1; class C1; end end end
      class D1; class E1; module F1; end end end
      A1::B1::C1.include D1::E1::F1
    eof

    expect(YARD::Registry.root.instance_mixins).not_to eq [P('D1::E1::F1')]
    expect(P('A1::B1::C1').instance_mixins).to eq [P('D1::E1::F1')]
  end

  it "resolves modules that mix themselves in" do
    expect(Registry.at('Foo').mixins).to match_array [P('MixMySelfIn'), P('Nested::Foo')]
  end

  it "ensures the recipient is loaded from another file" do
    # 002 includes a module into a module defined in 003
    parse_file [:mixin_handler_002, :mixin_handler_003], __FILE__

    expect(P('A1').instance_mixins).to eq [P('B1')]
  end
end
