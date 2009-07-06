require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

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
  end
end