# frozen_string_literal: true

RSpec.describe YARD::Templates::Helpers::MethodHelper do
  include YARD::Templates::Helpers::BaseHelper
  include YARD::Templates::Helpers::MethodHelper

  describe "#format_args" do
    it "displays keyword arguments" do
      params = [['a:', '1'], ['b:', '2'], ['**kwargs', nil]]
      YARD.parse_string 'def foo; end'
      allow(Registry.at('#foo')).to receive(:parameters) { params }
      expect(format_args(Registry.at('#foo'))).to eq '(a: 1, b: 2, **kwargs)'
    end

    it "does not show &blockarg if no @param tag and has @yield" do
      YARD.parse_string <<-EOF
        # @yield blah
        def foo(&block); end
      EOF
      expect(format_args(Registry.at('#foo'))).to eq ''
    end

    it "does not show &blockarg if no @param tag and has @yieldparam" do
      YARD.parse_string <<-EOF
        # @yieldparam blah test
        def foo(&block); end
      EOF
      expect(format_args(Registry.at('#foo'))).to eq ''
    end

    it "shows &blockarg if @param block is documented (even with @yield)" do
      YARD.parse_string <<-EOF
        # @yield [a,b]
        # @yieldparam a test
        # @param block test
        def foo(&block) end
      EOF
      expect(format_args(Registry.at('#foo'))).to eq '(&block)'
    end
  end

  describe "#format_block" do
    before { YARD::Registry.clear }

    it "shows block for method with yield" do
      YARD.parse_string <<-EOF
        def foo; yield(a, b, c) end
      EOF
      expect(format_block(Registry.at('#foo'))).to eq "{|a, b, c| ... }"
    end

    it "shows block for method with @yieldparam tags" do
      YARD.parse_string <<-EOF
        # @yieldparam _self me!
        def foo; end
      EOF
      expect(format_block(Registry.at('#foo'))).to eq "{|_self| ... }"
    end

    it "shows block for method with @yield but no types" do
      YARD.parse_string <<-EOF
        # @yield blah
        # @yieldparam a
        def foo; end

        # @yield blah
        def foo2; end
      EOF
      expect(format_block(Registry.at('#foo'))).to eq "{|a| ... }"
      expect(format_block(Registry.at('#foo2'))).to eq "{ ... }"
    end

    it "shows block for method with @yield and types" do
      YARD.parse_string <<-EOF
        # @yield [a, b, c] blah
        # @yieldparam a
        def foo; end
      EOF
      expect(format_block(Registry.at('#foo'))).to eq "{|a, b, c| ... }"
    end
  end

  describe "#format_constant" do
    include YARD::Templates::Helpers::HtmlHelper

    it "displays correctly constant values which are quoted symbols" do
      YARD.parse_string %(
        class TestFmtConst
          Foo = :''
          Bar = :BAR
          Baz = :'B+z'
        end
      )
      # html_syntax_highlight will be called by format_constant for
      # Foo, Bar and Baz and in turn will enquire for options.highlight
      expect(self).to receive(:options).exactly(3).times.and_return(
        Options.new.update(:highlight => false)
      )
      foo, bar, baz = %w(Foo Bar Baz).map do |c|
        Registry.at("TestFmtConst::#{c}").value
      end
      expect(format_constant(foo)).to eq ":&#39;&#39;"
      expect(format_constant(bar)).to eq ':BAR'
      expect(format_constant(baz)).to eq ":&#39;B+z&#39;"
    end

    context "when an empty string is passed as param" do
      it "returns an empty string" do
        # html_syntax_highlight will be called by format_constant
        # and in turn will enquire for options.highlight
        expect(self).to receive(:options).once.and_return(
          Options.new.update(:highlight => false)
        )

        expect(format_constant("")).to eq ""
      end
    end
  end
end
