require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

if RUBY19
  describe YARD::Parser::Ruby::RubyParser do
    def stmt(stmt) 
      YARD::Parser::Ruby::RubyParser.new(stmt, nil).parse.root.first
    end
    
    describe '#parse' do
      it "should get comment line numbers" do
        s = stmt <<-eof
          # comment
          # comment
          # comment
          def method; end
        eof
        s.comments.should == "comment\ncomment\ncomment"
        s.comments_range.should == (1..3)

        s = stmt <<-eof

          # comment
          # comment
          def method; end
        eof
        s.comments.should == "comment\ncomment"
        s.comments_range.should == (2..3)

        s = stmt <<-eof
          # comment
          # comment

          def method; end
        eof
        s.comments.should == "comment\ncomment"
        s.comments_range.should == (1..2)

        s = stmt <<-eof
          # comment
          def method; end
        eof
        s.comments.should == "comment"
        s.comments_range.should == (1..1)

        s = stmt <<-eof
          def method; end # comment
        eof
        s.comments.should == "comment"
        s.comments_range.should == (1..1)
      end
      
      it "should handle 1.9 lambda syntax with args" do
        src = "->(a,b,c=1,*args,&block) { hello_world }"
        stmt(src).source.should == src
      end
      
      it "should handle 1.9 lambda syntax" do
        src = "-> { hello_world }"
        stmt(src).source.should == src
      end
          
      it "should handle standard lambda syntax" do
        src = "lambda { hello_world }"
        stmt(src).source.should == src
      end
      
      it "should throw a ParserSyntaxError on invalid code" do
        lambda { stmt("Foo, bar.") }.should raise_error(YARD::Parser::ParserSyntaxError)
      end
      
      it "should handle bare hashes as method parameters" do
        src = "command :a => 1, :b => 2, :c => 3"
        stmt(src).jump(:command)[1].source.should == ":a => 1, :b => 2, :c => 3"
        
        src = "command a: 1, b: 2, c: 3"
        stmt(src).jump(:command)[1].source.should == "a: 1, b: 2, c: 3"
      end
      
      it "should handle source for hash syntax" do
        src = "{ :a => 1, :b => 2, :c => 3 }"
        stmt(src).jump(:hash).source.should == "{ :a => 1, :b => 2, :c => 3 }"
      end
      
      it "should handle an empty hash" do
        stmt("{}").jump(:hash).source.should == "{}"
      end
      
      it "new hash label syntax should show label without colon" do
        ast = stmt("{ a: 1 }").jump(:label)
        ast[0].should == "a"
        ast.source.should == "a:"
      end
      
      it "should handle begin/rescue blocks" do
        ast = stmt("begin; X; rescue => e; Y end").jump(:rescue)
        ast.source.should == "rescue => e; Y end"

        ast = stmt("begin; X; rescue A => e; Y end").jump(:rescue)
        ast.source.should == "rescue A => e; Y end"

        ast = stmt("begin; X; rescue A, B => e; Y end").jump(:rescue)
        ast.source.should == "rescue A, B => e; Y end"
      end
      
      it "should handle method rescue blocks" do
        ast = stmt("def x; A; rescue Y; B end")
        ast.source.should == "def x; A; rescue Y; B end"
        ast.jump(:rescue).source.should == "rescue Y; B end"
      end
    end
  end
end