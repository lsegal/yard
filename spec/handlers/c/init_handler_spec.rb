# frozen_string_literal: true
require "#{File.dirname(__FILE__)}/spec_helper"

RSpec.describe YARD::Handlers::C::InitHandler do
  it "adds documentation in Init_ClassName() to ClassName" do
    parse(<<-EOF)
      // Bar!
      void Init_A() {
        rb_cA = rb_define_class("A", rb_cObject);
      }
    EOF
    expect(Registry.at('A').docstring).to eq 'Bar!'
  end

  it "does not add documentation if ClassName is not created in Init" do
    parse(<<-EOF)
      // Bar!
      void Init_A() {
      }
    EOF
    expect(Registry.at('A')).to be nil
  end

  it "does not overwrite override comment" do
    parse(<<-EOF)
      /* Document-class: A
       * Foo!
       */

      // Bar!
      static SWIGEXPORT void Init_A() {
        rb_cA = rb_define_class("A", rb_cObject);
      }
    EOF
    expect(Registry.at('A').docstring).to eq 'Foo!'
  end

  it "checks non-Init methods for declarations too" do
    parse(<<-EOF)
      void foo(int x, int y, char *name) {
        rb_cB = rb_define_class("B", rb_cObject);
        rb_define_method(rb_cB, "foo", foo_impl, 0);
      }
    EOF
    expect(Registry.at('B')).to be_a(CodeObjects::ClassObject)
    expect(Registry.at('B#foo')).to be_a(CodeObjects::MethodObject)
  end
end
