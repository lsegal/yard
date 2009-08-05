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
    end
  end
end