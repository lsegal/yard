require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')
require 'pp'
require 'stringio'

include YARD::Parser::Ruby

if RUBY19
  describe YARD::Parser::Ruby::AstNode do
    describe "#jump" do
      it "should jump to the first specific inner node if found" do
        ast = s(:paren, s(:paren, s(:params, s(s(:ident, "hi"), s(:ident, "bye")))))
        ast.jump(:params)[0][0].type.should equal(:ident)
      end
  
      it "should return the original ast if no inner node is found" do
        ast = s(:paren, s(:list, s(:list, s(s(:ident, "hi"), s(:ident, "bye")))))
        ast.jump(:params).object_id.should == ast.object_id
      end
    end
    
    describe '#pretty_print' do
      it "should show a list of nodes" do
        out = StringIO.new
        PP.pp(s(:paren, s(:list, s(:ident, "bye"), line: 1)), out)
        out.rewind
        out.read.should == "s(:paren,\n   s(s(:ident, \"bye\", line: 0...0, source: 0...0), line: 1, source: 0..0))\n"
      end
    end
  end
end