require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::ClassHandler do
  it "should register modules" do
    parse_init 'mFoo = rb_define_module("Foo");'
    Registry.at('Foo').type.should == :module
  end

  it "should register classes under namespaces" do
    parse_init 'mFoo = rb_define_module_under(mBar, "Foo");'
    Registry.at('Bar::Foo').type.should == :module
  end

  it "should remember symbol defined with class" do
    parse_init(<<-eof)
      cXYZ = rb_define_module("Foo");
      rb_define_method(cXYZ, "bar", bar, 0);
    eof
    Registry.at('Foo').type.should == :module
    Registry.at('Foo#bar').should_not be_nil
  end

  it "should not associate declaration comments as module docstring" do
    parse_init(<<-eof)
      /* Docstring! */
      mFoo = rb_define_module("Foo");
    eof
    Registry.at('Foo').docstring.should be_blank
  end

  it "should associate a file with the declaration" do
    parse_init(<<-eof)
      mFoo = rb_define_module("Foo");
    eof
    Registry.at('Foo').file.should == '(stdin)'
    Registry.at('Foo').line.should == 2
  end
end
