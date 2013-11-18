require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::InitHandler do
  it "should add documentation in Init_ClassName() to ClassName" do
    parse(<<-eof)
      // Bar!
      void Init_A() {
        rb_cA = rb_define_class("A", rb_cObject);
      }
    eof
    expect(Registry.at('A').docstring).to eq 'Bar!'
  end

  it "should not add documentation if ClassName is not created in Init" do
    parse(<<-eof)
      // Bar!
      void Init_A() {
      }
    eof
    expect(Registry.at('A')).to be_nil
  end

  it "should not overwrite override comment" do
    parse(<<-eof)
      /* Document-class: A
       * Foo!
       */

      // Bar!
      void Init_A() {
        rb_cA = rb_define_class("A", rb_cObject);
      }
    eof
    expect(Registry.at('A').docstring).to eq 'Foo!'
  end

  it "should check non-Init methods for declarations too" do
    parse(<<-eof)
      void foo(int x, int y, char *name) {
        rb_cB = rb_define_class("B", rb_cObject);
        rb_define_method(rb_cB, "foo", foo_impl, 0);
      }
    eof
    expect(Registry.at('B')).to be_a(CodeObjects::ClassObject)
    expect(Registry.at('B#foo')).to be_a(CodeObjects::MethodObject)
  end
end
