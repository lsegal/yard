require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe YARD::Parser::C::CParser do
  describe '#parse' do
    def parse(contents)
      Registry.clear
      YARD.parse_string(contents, :c)
    end

    describe 'Array class' do
      before(:all) do
        file = File.join(File.dirname(__FILE__), 'examples', 'array.c.txt')
        parse(File.read(file))
      end

      it "should parse Array class" do
        obj = YARD::Registry.at('Array')
        expect(obj).to_not be_nil
        expect(obj.docstring).to_not be_blank
      end

      it "should parse method" do
        obj = YARD::Registry.at('Array#initialize')
        expect(obj.docstring).to_not be_blank
        expect(obj.tags(:overload).size).to be > 1
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
        expect(File).to receive(:read).with('extra.c').and_return(extra_contents)
        parse(@contents)
        expect(Registry.at('Multifile#extra').docstring).to eq 'foo'
      end

      it "should stop searching for extra source file gracefully if file is not found" do
        expect(File).to receive(:read).with('extra.c').and_raise(Errno::ENOENT)
        expect(log).to receive(:warn).with("Missing source file `extra.c' when parsing Multifile#extra")
        parse(@contents)
        expect(Registry.at('Multifile#extra').docstring).to eq ''
      end

      it "should differentiate between a struct and a pointer to a struct retval" do
        parse(@contents)
        expect(Registry.at('Multifile#hello_mars').docstring).to eq 'Hello Mars'
      end
    end

    describe 'Foo class' do
      it 'should not include comments in docstring source' do
        parse <<-eof
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
        expect(Registry.at('Foo#foo').source.gsub(/\s\s+/, ' ')).
          to eq "VALUE foo(VALUE x) { int value = x;\n}"
      end
    end

    describe 'Constant' do
      it 'should not truncate docstring' do
        parse <<-eof
          #define MSK_DEADBEEF 0xdeadbeef
          void
          Init_Mask(void)
          {
              rb_cMask  = rb_define_class("Mask", rb_cObject);
              /* 0xdeadbeef: This constant is frequently used to indicate a
               * software crash or deadlock in embedded systems. */
              rb_define_const(rb_cMask, "DEADBEEF", INT2FIX(MSK_DEADBEEF));
          }
        eof
        constant = Registry.at('Mask::DEADBEEF')
        expect(constant.value).to eq '0xdeadbeef'
        expect(constant.docstring).to eq "This constant is frequently used to indicate a\nsoftware crash or deadlock in embedded systems."
      end
    end

    describe 'Macros' do
      it "should handle param## inside of macros" do
        thr = Thread.new do
          parse <<-eof
          void
          Init_gobject_gparamspecs(void)
          {
              VALUE cParamSpec = GTYPE2CLASS(G_TYPE_PARAM);
              VALUE c;

          #define DEF_NUMERIC_PSPEC_METHODS(c, typename) \
            G_STMT_START {\
              rbg_define_method(c, "initialize", typename##_initialize, 7); \
              rbg_define_method(c, "minimum", typename##_minimum, 0); \
              rbg_define_method(c, "maximum", typename##_maximum, 0); \
              rbg_define_method(c, "range", typename##_range, 0); \
            } G_STMT_END

          #if 0
              rbg_define_method(c, "default_value", typename##_default_value, 0); \
              rb_define_alias(c, "default", "default_value"); \

          #endif

              c = G_DEF_CLASS(G_TYPE_PARAM_CHAR, "Char", cParamSpec);
              DEF_NUMERIC_PSPEC_METHODS(c, char);
          eof
        end
        thr.join(5)
        if thr.alive?
          fail "Did not parse in time"
          thr.kill
        end
      end
    end
  end

  describe 'Override comments' do
    before(:all) do
      Registry.clear
      override_file = File.join(File.dirname(__FILE__), 'examples', 'override.c.txt')
      @override_parser = YARD.parse_string(File.read(override_file), :c)
    end

    it "should parse GMP::Z class" do
      z = YARD::Registry.at('GMP::Z')
      expect(z).to_not be_nil
      expect(z.docstring).to_not be_blank
    end

    it "should parse GMP::Z methods w/ bodies" do
      add = YARD::Registry.at('GMP::Z#+')
      expect(add.docstring).to_not be_blank
      expect(add.source).to_not be_nil
      expect(add.source).to_not be_empty

      add_self = YARD::Registry.at('GMP::Z#+')
      expect(add_self.docstring).to_not be_blank
      expect(add_self.source).to_not be_nil
      expect(add_self.source).to_not be_empty

      sqrtrem = YARD::Registry.at('GMP::Z#+')
      expect(sqrtrem.docstring).to_not be_blank
      expect(sqrtrem.source).to_not be_nil
      expect(sqrtrem.source).to_not be_empty
    end

    it "should parse GMP::Z methods w/o bodies" do
      neg = YARD::Registry.at('GMP::Z#neg')
      expect(neg.docstring).to_not be_blank
      expect(neg.source).to be_nil

      neg_self = YARD::Registry.at('GMP::Z#neg')
      expect(neg_self.docstring).to_not be_blank
      expect(neg_self.source).to be_nil
    end
  end
end
