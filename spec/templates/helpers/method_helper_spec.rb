require File.dirname(__FILE__) + "/../spec_helper"

describe YARD::Templates::Helpers::MethodHelper do
  include YARD::Templates::Helpers::BaseHelper
  include YARD::Templates::Helpers::MethodHelper

  describe '#format_args' do
    it "should not show &blockarg if no @param tag and has @yield" do
      YARD.parse_string <<-'eof'
        # @yield blah
        def foo(&block); end
      eof
        expect(format_args(Registry.at('#foo'))).to eq ''
    end

    it "should not show &blockarg if no @param tag and has @yieldparam" do
      YARD.parse_string <<-'eof'
        # @yieldparam blah test
        def foo(&block); end
      eof
        expect(format_args(Registry.at('#foo'))).to eq ''
    end

    it "should show &blockarg if @param block is documented (even with @yield)" do
      YARD.parse_string <<-'eof'
        # @yield [a,b]
        # @yieldparam a test
        # @param block test
        def foo(&block) end
      eof
        expect(format_args(Registry.at('#foo'))).to eq '(&block)'
    end
  end

  describe '#format_block' do
    before { YARD::Registry.clear }

    it "should show block for method with yield" do
      YARD.parse_string <<-'eof'
        def foo; yield(a, b, c) end
      eof
        expect(format_block(Registry.at('#foo'))).to eq "{|a, b, c| ... }"
    end

    it "should show block for method with @yieldparam tags" do
      YARD.parse_string <<-'eof'
        # @yieldparam _self me!
        def foo; end
      eof
        expect(format_block(Registry.at('#foo'))).to eq "{|_self| ... }"
    end

    it "should show block for method with @yield but no types" do
      YARD.parse_string <<-'eof'
        # @yield blah
        # @yieldparam a
        def foo; end

        # @yield blah
        def foo2; end
      eof
        expect(format_block(Registry.at('#foo'))).to eq "{|a| ... }"
        expect(format_block(Registry.at('#foo2'))).to eq "{ ... }"
    end

    it "should show block for method with @yield and types" do
      YARD.parse_string <<-'eof'
        # @yield [a, b, c] blah
        # @yieldparam a
        def foo; end
      eof
        expect(format_block(Registry.at('#foo'))).to eq "{|a, b, c| ... }"
    end
  end
end
