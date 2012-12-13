require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::MethodHandler do
  it "should register methods" do
    parse_init <<-eof
      mFoo = rb_define_module("Foo");
      rb_define_method(mFoo, "bar", bar, 0);
    eof
    Registry.at('Foo#bar').should_not be_nil
    expect(Registry.at('Foo#bar').visibility).to eq :public
  end

  it "should register private methods" do
    parse_init <<-eof
      mFoo = rb_define_module("Foo");
      rb_define_private_method(mFoo, "bar", bar, 0);
    eof
    Registry.at('Foo#bar').should_not be_nil
    expect(Registry.at('Foo#bar').visibility).to eq :private
  end

  it "should register singleton methods" do
    parse_init <<-eof
      mFoo = rb_define_module("Foo");
      rb_define_singleton_method(mFoo, "bar", bar, 0);
    eof
    Registry.at('Foo.bar').should_not be_nil
    expect(Registry.at('Foo.bar').visibility).to eq :public
  end

  it "should register module functions" do
    parse <<-eof
      /* DOCSTRING
       * @return [String] foo!
      */
      static VALUE bar(VALUE self) { x(); y(); z(); }

      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_module_function(mFoo, "bar", bar, 0);
      }
    eof
    bar_c = Registry.at('Foo.bar')
    bar_i = Registry.at('Foo#bar')
    bar_c.should be_module_function
    expect(bar_c.visibility).to eq :public
    expect(bar_c.docstring).to eq "DOCSTRING"
    expect(bar_c.tag(:return).object).to eq bar_c
    expect(bar_c.source).to eq "static VALUE bar(VALUE self) { x(); y(); z(); }"
    bar_i.should_not be_module_function
    expect(bar_i.visibility).to eq :private
    expect(bar_i.docstring).to eq "DOCSTRING"
    expect(bar_i.tag(:return).object).to eq bar_i
    expect(bar_i.source).to eq bar_c.source
  end

  it "should register global functions into Kernel" do
    parse_init 'rb_define_global_function("bar", bar, 0);'
    Registry.at('Kernel#bar').should_not be_nil
  end

  it "should look for symbol containing method source" do
    parse <<-eof
      static VALUE foo(VALUE self) { x(); y(); z(); }
      VALUE bar() { a(); b(); c(); }
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo", foo, 0);
        rb_define_method(mFoo, "bar", bar, 0);
      }
    eof
    foo = Registry.at('Foo#foo')
    bar = Registry.at('Foo#bar')
    expect(foo.source).to eq "static VALUE foo(VALUE self) { x(); y(); z(); }"
    expect(foo.file).to eq '(stdin)'
    expect(foo.line).to eq 1
    expect(bar.source).to eq "VALUE bar() { a(); b(); c(); }"
    expect(bar.file).to eq '(stdin)'
    expect(bar.line).to eq 2
  end

  it "should find docstrings attached to method symbols" do
    parse <<-eof
      /* DOCSTRING */
      static VALUE foo(VALUE self) { x(); y(); z(); }
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo", foo, 0);
      }
    eof
    foo = Registry.at('Foo#foo')
    expect(foo.docstring).to eq 'DOCSTRING'
  end

  it "should use declaration comments as docstring if there are no others" do
    parse <<-eof
      static VALUE foo(VALUE self) { x(); y(); z(); }
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        /* DOCSTRING */
        rb_define_method(mFoo, "foo", foo, 0);
        // DOCSTRING!
        rb_define_method(mFoo, "bar", bar, 0);
      }
    eof
    foo = Registry.at('Foo#foo')
    expect(foo.docstring).to eq 'DOCSTRING'
    bar = Registry.at('Foo#bar')
    expect(bar.docstring).to eq 'DOCSTRING!'
  end

  it "should look for symbols in other file" do
    other = <<-eof
      /* DOCSTRING! */
      static VALUE foo() { x(); }
    eof
    File.should_receive(:read).with('other.c').and_return(other)
    parse <<-eof
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo", foo, 0); // in other.c
      }
    eof
    foo = Registry.at('Foo#foo')
    expect(foo.docstring).to eq 'DOCSTRING!'
    expect(foo.file).to eq 'other.c'
    expect(foo.line).to eq 2
    expect(foo.source).to eq 'static VALUE foo() { x(); }'
  end

  it "should allow extra file to include /'s and other filename characters" do
    File.should_receive(:read).at_least(1).times.with('ext/a-file.c').and_return(<<-eof)
      /* FOO */
      VALUE foo(VALUE x) { int value = x; }

      /* BAR */
      VALUE bar(VALUE x) { int value = x; }
    eof
    parse_init <<-eof
      rb_define_method(rb_cFoo, "foo", foo, 1); /* in ext/a-file.c */
      rb_define_global_function("bar", bar, 1); /* in ext/a-file.c */
    eof
    expect(Registry.at('Foo#foo').docstring).to eq 'FOO'
    expect(Registry.at('Kernel#bar').docstring).to eq 'BAR'
  end

  it "should warn if other file can't be found" do
    log.should_receive(:warn).with(/Missing source file `other.c' when parsing Foo#foo/)
    parse <<-eof
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo", foo, 0); // in other.c
      }
    eof
  end

  it "should look at override comments for docstring" do
    parse <<-eof
      /* Document-method: Foo::foo
       * Document-method: new
       * Document-method: Foo::Bar#baz
       * Foo bar!
       */

      // init comments
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo", foo, 0);
        rb_define_method(mFoo, "initialize", foo, 0);
        mBar = rb_define_module_under(mFoo, "Bar");
        rb_define_method(mBar, "baz", foo, 0);
      }
    eof
    expect(Registry.at('Foo#foo').docstring).to eq 'Foo bar!'
    expect(Registry.at('Foo#initialize').docstring).to eq 'Foo bar!'
    expect(Registry.at('Foo::Bar#baz').docstring).to eq 'Foo bar!'
  end

  it "should look at overrides in other files" do
    other = <<-eof
      /* Document-method: Foo::foo
       * Document-method: new
       * Document-method: Foo::Bar#baz
       * Foo bar!
       */
    eof
    File.should_receive(:read).with('other.c').and_return(other)
    parse <<-eof
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo", foo, 0); // in other.c
        rb_define_method(mFoo, "initialize", foo, 0); // in other.c
        mBar = rb_define_module_under(mFoo, "Bar"); // in other.c
        rb_define_method(mBar, "baz", foo, 0); // in other.c
      }
    eof
    expect(Registry.at('Foo#foo').docstring).to eq 'Foo bar!'
    expect(Registry.at('Foo#initialize').docstring).to eq 'Foo bar!'
    expect(Registry.at('Foo::Bar#baz').docstring).to eq 'Foo bar!'
  end

  it "should add return tag on methods ending in '?'" do
    parse <<-eof
      /* DOCSTRING */
      static VALUE foo(VALUE self) { x(); y(); z(); }
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo?", foo, 0);
      }
    eof
    foo = Registry.at('Foo#foo?')
    expect(foo.docstring).to eq 'DOCSTRING'
    expect(foo.tag(:return).types).to eq ['Boolean']
  end

  it "should not add return tag if return tags exist" do
    parse <<-eof
      // @return [String] foo
      static VALUE foo(VALUE self) { x(); y(); z(); }
      void Init_Foo() {
        mFoo = rb_define_module("Foo");
        rb_define_method(mFoo, "foo?", foo, 0);
      }
    eof
    foo = Registry.at('Foo#foo?')
    expect(foo.tag(:return).types).to eq ['String']
  end
end
