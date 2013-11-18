require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::ClassHandler do
  it "should register modules" do
    parse_init 'mFoo = rb_define_module("Foo");'
    expect(Registry.at('Foo').type).to eq :module
  end

  it "should register classes under namespaces" do
    parse_init 'mFoo = rb_define_module_under(mBar, "Foo");'
    expect(Registry.at('Bar::Foo').type).to eq :module
  end

  it "should remember symbol defined with class" do
    parse_init(<<-eof)
      cXYZ = rb_define_module("Foo");
      rb_define_method(cXYZ, "bar", bar, 0);
    eof
    expect(Registry.at('Foo').type).to eq :module
    expect(Registry.at('Foo#bar')).to_not be_nil
  end

  it "should not associate declaration comments as module docstring" do
    parse_init(<<-eof)
      /* Docstring! */
      mFoo = rb_define_module("Foo");
    eof
    expect(Registry.at('Foo').docstring).to be_blank
  end

  it "should associate a file with the declaration" do
    parse_init(<<-eof)
      mFoo = rb_define_module("Foo");
    eof
    expect(Registry.at('Foo').file).to eq '(stdin)'
    expect(Registry.at('Foo').line).to eq 2
  end
end
