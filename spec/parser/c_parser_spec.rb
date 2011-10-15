require File.join(File.dirname(__FILE__), '..', 'spec_helper')
begin require 'continuation'; rescue LoadError; end unless RUBY18

class YARD::Parser::CParser; def ensure_loaded!(a, b=1) a end end

describe YARD::Parser::CParser do
  describe '#parse' do
    before(:all) do
      file = File.join(File.dirname(__FILE__), 'examples', 'array.c.txt')
      @parser = Parser::CParser.new(IO.read(file))
      @parser.parse
    end

    def parse
      Registry.clear
      Parser::CParser.new(@contents).parse
    end

    describe 'Array class' do
      it "should parse Array class" do
        obj = YARD::Registry.at('Array')
        obj.should_not be_nil
        obj.docstring.should_not be_blank
      end

      it "should parse method" do
        obj = YARD::Registry.at('Array#initialize')
        obj.docstring.should_not be_blank
        obj.tags(:overload).size.should > 1
      end
    end
    
    describe 'Source located in extra files' do
      before(:all) do
        @multifile = File.join(File.dirname(__FILE__), 'examples', 'multifile.c.txt')
        @extrafile = File.join(File.dirname(__FILE__), 'examples', 'extrafile.c.txt')
        @contents = File.read(@multifile)
      end
      
      it "should look for methods in extra files (if 'in' comment is found)" do
        extra_contents = File.read(@extrafile)
        File.should_receive(:read).with('extra.c').and_return(extra_contents)
        parse
        Registry.at('Multifile#extra').docstring.should == 'foo'
      end

      it "should stop searching for extra source file gracefully if file is not found" do
        File.should_receive(:read).with('extra.c').and_raise(Errno::ENOENT)
        log.should_receive(:warn).with("Missing source file `extra.c' when parsing Multifile#extra")
        parse
        Registry.at('Multifile#extra').docstring.should == ''
      end
    end
    
    describe 'Foo class' do
      it 'should not include comments in docstring source' do
        @contents = <<-eof
          /* 
           * Hello world
           */
          VALUE foo(VALUE x) {
            int value = x;
          }
          
          void Init_Foo() {
            rb_define_method(rb_cFoo, "foo", foo, 1);
          }
        eof
        parse
        Registry.at('Foo#foo').source.gsub(/\s\s+/, ' ').should == 
          "VALUE foo(VALUE x) { int value = x;\n}"
      end
    end
    
    describe 'Defining methods with source in other files' do
      it "should look in another file for method" do
        File.should_receive(:read).at_least(1).times.with('file.c').and_return(<<-eof)
          /* FOO
           */
          VALUE foo(VALUE x) 
          { }

          /* BAR
           */
          VALUE bar(VALUE x) 
          { }
        eof
        @contents = <<-eof
          void Init_Foo() {
            rb_define_method(rb_cFoo, "foo", foo, 1); /* in file.c */
            rb_define_global_function("bar", bar, 1); /* in file.c */
          }
        eof
        parse
        Registry.at('Foo#foo').docstring.should == 'FOO'
        Registry.at('Kernel#bar').docstring.should == 'BAR'
      end

      it "should allow extra file to include /'s and other filename characters" do
        File.should_receive(:read).at_least(1).times.with('ext/a-file.c').and_return(<<-eof)
          /* FOO
           */
          VALUE foo(VALUE x) {
            int value = x;
          }
          
          /* BAR
           */
          VALUE bar(VALUE x) {
            int value = x;
          }
        eof
        @contents = <<-eof
          void Init_Foo() {
            rb_define_method(rb_cFoo, "foo", foo, 1); /* in ext/a-file.c */
            rb_define_global_function("bar", bar, 1); /* in ext/a-file.c */
          }
        eof
        parse
        Registry.at('Foo#foo').docstring.should == 'FOO'
        Registry.at('Kernel#bar').docstring.should == 'BAR'
      end
    end
    
    describe 'Defining attributes' do
      before do
        Registry.clear
      end
      
      def run(read, write, commented = nil)
        @contents = <<-eof
          /* FOO */
          VALUE foo(VALUE x) { int value = x; }
          void Init_Foo() {
            rb_cFoo = rb_define_class("Foo", rb_cObject);
            #{commented ? '/*' : ''} 
              rb_define_attr(rb_cFoo, "foo", foo, #{read}, #{write});
            #{commented ? '*/' : ''}
          }
        eof
        parse
      end
      
      it "should handle readonly attribute (rb_define_attr)" do
        run(1, 0)
        Registry.at('Foo#foo').should be_reader
        Registry.at('Foo#foo=').should be_nil
      end

      it "should handle writeonly attribute (rb_define_attr)" do
        run(0, 1)
        Registry.at('Foo#foo').should be_nil
        Registry.at('Foo#foo=').should be_writer
      end

      it "should handle readwrite attribute (rb_define_attr)" do
        run(1, 1)
        Registry.at('Foo#foo').should be_reader
        Registry.at('Foo#foo=').should be_writer
      end

      it "should handle commented writeonly attribute (/* rb_define_attr */)" do
        run(1, 1, true)
        Registry.at('Foo#foo').should be_reader
        Registry.at('Foo#foo=').should be_writer
      end
    end
  end

  describe '#find_override_comment' do
    before(:all) do
      override_file = File.join(File.dirname(__FILE__), 'examples', 'override.c.txt')
      @override_parser = Parser::CParser.new(IO.read(override_file)).parse
    end
    
    it "should parse GMP::Z class" do
      z = YARD::Registry.at('GMP::Z')
      z.should_not be_nil
      z.docstring.should_not be_blank
    end

    it "should parse GMP::Z methods w/ bodies" do
      add = YARD::Registry.at('GMP::Z#+')
      add.docstring.should_not be_blank
      add.source.should_not be_nil
      add.source.should_not be_empty

      add_self = YARD::Registry.at('GMP::Z#+')
      add_self.docstring.should_not be_blank
      add_self.source.should_not be_nil
      add_self.source.should_not be_empty

      sqrtrem = YARD::Registry.at('GMP::Z#+')
      sqrtrem.docstring.should_not be_blank
      sqrtrem.source.should_not be_nil
      sqrtrem.source.should_not be_empty
    end

    it "should parse GMP::Z methods w/o bodies" do
      neg = YARD::Registry.at('GMP::Z#neg')
      neg.docstring.should_not be_blank
      neg.source.should be_nil

      neg_self = YARD::Registry.at('GMP::Z#neg')
      neg_self.docstring.should_not be_blank
      neg_self.source.should be_nil
    end
  end
end