require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::InitHandler do
  it "should add documentation in Init_ClassName() to ClassName" do
    parse(<<-eof)
      // Bar!
      void Init_A() {
        rb_cA = rb_define_class("A", rb_cObject);
      }
    eof
    Registry.at('A').docstring.should == 'Bar!'
  end

  it "should not add documentation if ClassName is not created in Init" do
    parse(<<-eof)
      // Bar!
      void Init_A() {
      }
    eof
    Registry.at('A').should be_nil
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
    Registry.at('A').docstring.should == 'Foo!'
  end
end
