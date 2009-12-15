require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

if RUBY19
  describe YARD::Parser::Ruby::RubyParser do
    def stmt(stmt) 
      YARD::Parser::Ruby::RubyParser.new(stmt, nil).parse.root.first
    end
    
    def stmts(stmts)
      YARD::Parser::Ruby::RubyParser.new(stmts, nil).parse.root
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
      
      it "should only look up to two lines back for comments" do
        s = stmt <<-eof
          # comments

          # comments

          def method; end
        eof
        s.comments.should == "comments"

        s = stmt <<-eof
          # comments


          def method; end
        eof
        s.comments.should == nil

        ss = stmts <<-eof
          # comments


          def method; end

          # hello
          def method2; end
        eof
        ss[0].comments.should == nil
        ss[1].comments.should == 'hello'
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
      
      it "should handle defs with keywords as method name" do
        ast = stmt("# docstring\nclass A;\ndef class; end\nend")
        ast.jump(:class).docstring.should == "docstring"
        ast.jump(:class).line_range.should == (2..4)
      end
      
      it "should end source properly on array reference" do
        ast = stmt("AS[0, 1 ]   ")
        ast.source.should == 'AS[0, 1 ]'

        ast = stmt("def x(a = S[1]) end").jump(:default_arg)
        ast.source.should == 'a = S[1]'
      end
      
      it "should end source properly on if/unless mod" do
        %w(if unless while).each do |mod|
          stmt("A=1 #{mod} true").source.should == "A=1 #{mod} true"
        end
      end
      
      it "should show proper source for assignment" do
        stmt("A=1").jump(:assign).source.should == "A=1"
      end
    end
  end
end