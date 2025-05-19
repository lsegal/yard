# frozen_string_literal: true
require 'pp'
require 'stringio'

include YARD::Parser::Ruby

RSpec.describe YARD::Parser::Ruby::AstNode do
  describe "#jump" do
    it "jumps to the first specific inner node if found" do
      ast = s(:paren, s(:paren, s(:params, s(s(:ident, "hi"), s(:ident, "bye")))))
      expect(ast.jump(:params)[0][0].type).to equal(:ident)
    end

    it "returns the original ast if no inner node is found" do
      ast = s(:paren, s(:list, s(:list, s(s(:ident, "hi"), s(:ident, "bye")))))
      expect(ast.jump(:params).object_id).to eq ast.object_id
    end
  end

  describe "#pretty_print" do
    it "shows a list of nodes" do
      obj = YARD::Parser::Ruby::RubyParser.parse("# x\nbye", "x").ast
      out = StringIO.new
      PP.pp(obj, out)
      vcall = RUBY_VERSION >= '1.9.3' ? 'vcall' : 'var_ref'
      expect(out.string).to eq "s(s(:#{vcall},\n      " \
                               "s(:ident, \"bye\", line: 2..2, source: 4..6),\n      " \
                               "docstring: \"x\",\n      " \
                               "line: 2..2,\n      " \
                               "source: 4..6))\n"
    end
  end unless YARD.ruby31?

  describe "#line" do
    it "does not break on beginless or endless ranges" do
      skip "Unsupported ruby version" if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7')

      obj = YARD::Parser::Ruby::RubyParser.parse("# x\nbye", "x").ast
      # obj.range returns (2..2) in this case, but sometimes, this range is set
      # to a beginless or endless one.
      obj.line_range = Range.new(nil, 2)
      expect(obj.line).to eq 2
      obj.line_range = Range.new(2, nil)
      expect(obj.line).to eq 2
    end
  end

  describe "#reset_line_info" do
    it "does not break on beginless or endless ranges" do
      skip "Unsupported ruby version" if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.7')

      obj = YARD::Parser::Ruby::RubyParser.parse("# x\ndef fn(arg); 42; end", "x").ast
      obj = obj.first
      expect(obj.children.size).to eq 3
      fst = obj.children.first
      lst = obj.children.last
      fst.line_range = Range.new(nil, 10)
      fst.source_range = Range.new(nil, 10)
      lst.line_range = Range.new(2, nil)
      lst.source_range = Range.new(2, nil)
      obj.send(:reset_line_info)
      expect(obj.line_range).to eq Range.new(nil, nil)
      expect(obj.source_range).to eq Range.new(nil, nil)
    end
  end
end if HAVE_RIPPER
