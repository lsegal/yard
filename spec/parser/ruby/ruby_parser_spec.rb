require File.join(File.dirname(__FILE__), '..', '..', 'spec_helper')

describe YARD::Parser::Ruby::RubyParser do
  def stmt(stmt)
    YARD::Parser::Ruby::RubyParser.new(stmt, nil).parse.root.first
  end

  def stmts(stmts)
    YARD::Parser::Ruby::RubyParser.new(stmts, nil).parse.root
  end

  def tokenize(stmt)
    YARD::Parser::Ruby::RubyParser.new(stmt, nil).parse.tokens
  end

  describe '#parse' do
    it "should get comment line numbers" do
      s = stmt <<-eof
        # comment
        # comment
        # comment
        def method; end
      eof
        expect(s.comments).to eq "comment\ncomment\ncomment"
        expect(s.comments_range).to eq(1..3)

      s = stmt <<-eof

        # comment
        # comment
        def method; end
      eof
        expect(s.comments).to eq "comment\ncomment"
        expect(s.comments_range).to eq(2..3)

      s = stmt <<-eof
        # comment
        # comment

        def method; end
      eof
        expect(s.comments).to eq "comment\ncomment"
        expect(s.comments_range).to eq(1..2)

      s = stmt <<-eof
        # comment
        def method; end
      eof
        expect(s.comments).to eq "comment"
        expect(s.comments_range).to eq(1..1)

      s = stmt <<-eof
        def method; end # comment
      eof
        expect(s.comments).to eq "comment"
        expect(s.comments_range).to eq(1..1)
    end

    it "should only look up to two lines back for comments" do
      s = stmts <<-eof
        # comments

        # comments

        def method; end
      eof
        expect(s[1].comments).to eq "comments"

      s = stmts <<-eof
        # comments


        def method; end
      eof
        expect(s[1].comments).to eq nil

      ss = stmts <<-eof
        # comments


        def method; end

        # hello
        def method2; end
      eof
        expect(ss[1].comments).to eq nil
        expect(ss[2].comments).to eq 'hello'
    end

    it "should handle block comment followed by line comment" do
      ss = stmts <<-eof
# comments1

=begin
comments2
=end
# comments3
def hello; end
eof
expect(ss.last.comments).to eq "comments3"
    end

    it "should handle block comment followed by block comment" do
      ss = stmts <<-eof
=begin
comments1
=end
=begin
comments2
=end
def hello; end
eof
expect(ss.last.comments.strip).to eq "comments2"
    end

    it "should handle 1.9 lambda syntax with args" do
      src = "->(a,b,c=1,*args,&block) { hello_world }"
expect(stmt(src).source).to eq src
    end

    it "should handle 1.9 lambda syntax" do
      src = "-> { hello_world }"
expect(stmt(src).source).to eq src
    end

    it "should handle standard lambda syntax" do
      src = "lambda { hello_world }"
expect(stmt(src).source).to eq src
    end

    it "should throw a ParserSyntaxError on invalid code" do
      lambda { stmt("Foo, bar.") }.should raise_error(YARD::Parser::ParserSyntaxError)
    end

    it "should handle bare hashes as method parameters" do
      src = "command :a => 1, :b => 2, :c => 3"
expect(stmt(src).jump(:command)[1].source).to eq ":a => 1, :b => 2, :c => 3"

      src = "command a: 1, b: 2, c: 3"
expect(stmt(src).jump(:command)[1].source).to eq "a: 1, b: 2, c: 3"
    end

    it "should handle source for hash syntax" do
      src = "{ :a => 1, :b => 2, :c => 3 }"
expect(stmt(src).jump(:hash).source).to eq "{ :a => 1, :b => 2, :c => 3 }"
    end

    it "should handle an empty hash" do
expect(stmt("{}").jump(:hash).source).to eq "{}"
    end

    it "new hash label syntax should show label without colon" do
      ast = stmt("{ a: 1 }").jump(:label)
expect(ast[0]).to eq "a"
expect(ast.source).to eq "a:"
    end

    it "should handle begin/rescue blocks" do
      ast = stmt("begin; X; rescue => e; Y end").jump(:rescue)
expect(ast.source).to eq "rescue => e; Y end"

      ast = stmt("begin; X; rescue A => e; Y end").jump(:rescue)
expect(ast.source).to eq "rescue A => e; Y end"

      ast = stmt("begin; X; rescue A, B => e; Y end").jump(:rescue)
expect(ast.source).to eq "rescue A, B => e; Y end"
    end

    it "should handle method rescue blocks" do
      ast = stmt("def x; A; rescue Y; B end")
expect(ast.source).to eq "def x; A; rescue Y; B end"
expect(ast.jump(:rescue).source).to eq "rescue Y; B end"
    end

    it "should handle defs with keywords as method name" do
      ast = stmt("# docstring\nclass A;\ndef class; end\nend")
expect(ast.jump(:class).docstring).to eq "docstring"
expect(ast.jump(:class).line_range).to eq(2..4)
    end

    it "should end source properly on array reference" do
      ast = stmt("AS[0, 1 ]   ")
expect(ast.source).to eq 'AS[0, 1 ]'

      ast = stmt("def x(a = S[1]) end").jump(:default_arg)
expect(ast.source).to eq 'a = S[1]'
    end

    it "should end source properly on if/unless mod" do
      %w(if unless while).each do |mod|
  expect(stmt("A=1 #{mod} true").source).to eq "A=1 #{mod} true"
      end
    end

    it "should show proper source for assignment" do
expect(stmt("A=1").jump(:assign).source).to eq "A=1"
    end

    it "should show proper source for a top_const_ref" do
      s = stmt("::\nFoo::Bar")
expect(s.jump(:top_const_ref).source).to eq "::\nFoo"
      s.should be_ref
      s.jump(:top_const_ref).should be_ref
expect(s.source).to eq "::\nFoo::Bar"
expect(s.line_range.to_a).to eq [1, 2]
    end

    it "should show proper source for inline heredoc" do
      src = "def foo\n  foo(<<-XML, 1, 2)\n    bar\n\n  XML\nend"
      s = stmt(src)
      t = tokenize(src)
expect(s.source).to eq src
expect(t.map {|x| x[1] }.join).to eq src
    end

    it "should show proper source for regular heredoc" do
      src = "def foo\n  x = <<-XML\n  Hello \#{name}!\n  Bye!\n  XML\nend"
      s = stmt(src)
      t = tokenize(src)
expect(s.source).to eq src
expect(t.map {|x| x[1] }.join).to eq src
    end

    it "should show proper source for heredoc with comment" do
      src = "def foo\n  x = <<-XML # HI!\n  Hello \#{name}!\n  Bye!\n  XML\nend"
      s = stmt(src)
      t = tokenize(src)
expect(s.source).to eq src
expect(t.map {|x| x[1] }.join).to eq src
    end

    it "should show proper source for string" do
      ["'", '"'].each do |q|
        src = "#{q}hello\n\nworld#{q}"
        s = stmt(src)
  expect(s.jump(:string_content).source).to eq "hello\n\nworld"
  expect(s.source).to eq src
      end

      src = '("this is a string")'
expect(stmt(src).jump(:string_literal).source).to eq '"this is a string"'
    end

    it "should show proper source for %w() array" do
      src = "%w(\na b c\n d e f\n)"
expect(stmt(src).jump(:qwords_literal).source).to eq src
    end

    it "should show proper source for %w{} array" do
      src = "%w{\na b c\n d e f\n}"
expect(stmt(src).jump(:array).source).to eq src
    end

    it "should parse %w() array in constant declaration" do
      s = stmt(<<-eof)
        class Foo
          FOO = %w( foo bar )
        end
      eof
        expect(s.jump(:qwords_literal).source).to eq '%w( foo bar )'
      if RUBY_VERSION >= '1.9.3' # ripper fix: array node encapsulates qwords
        expect(s.jump(:array).source).to eq '%w( foo bar )'
      end
    end

    it "should parse %w() array source in object[] parsed context" do
      s = stmts(<<-eof)
        {}[:key]
        FOO = %w( foo bar )
      eof
        expect(s[1].jump(:array).source).to eq '%w( foo bar )'
    end

    it "should parse %w() array source in object[]= parsed context" do
      s = stmts(<<-eof)
        {}[:key] = :value
        FOO = %w( foo bar )
      eof
        expect(s[1].jump(:array).source).to eq '%w( foo bar )'
    end

    it "should parse [] as array" do
      s = stmt(<<-eof)
        class Foo
          FOO = ['foo', 'bar']
        end
      eof
        expect(s.jump(:array).source).to eq "['foo', 'bar']"
    end

    it "should show source for unary minus" do
        expect(stmt("X = - 1").jump(:unary).source).to eq '- 1'
    end

    it "should show source for unary exclamation" do
        expect(stmt("X = !1").jump(:unary).source).to eq '!1'
    end

    it "should find lone comments" do
      Registry.clear
      ast = YARD.parse_string(<<-eof).enumerator
        class Foo
          ##
          # comment here


          def foo; end

          # end comment
        end
      eof
      comment = ast.first.last.first
        expect(comment.type).to eq :comment
      comment.docstring_hash_flag.should be_true
        expect(comment.docstring.strip).to eq "comment here"

        expect(ast.first.last.last.type).to eq :comment
        expect(ast.first.last.last.docstring).to eq "end comment"
    end
  end
end if HAVE_RIPPER
