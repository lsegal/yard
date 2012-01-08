require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::OverrideCommentHandler do
  before { Registry.clear }
  
  [:class, :module].each do |type|
    it "should handle Document-#{type}" do
      cparse(<<-eof)
        /* Document-#{type}: A
         * Foo bar baz
         */
        void 
      eof
      Registry.at('A').type.should == type
      Registry.at('A').docstring.should == 'Foo bar baz'
    end
  end
  
  it "should handle multiple class/module combinations" do
    cparse(<<-eof)
      /* Document-class: A
       * Document-class: B
       * Document-module: C
       * Foo bar baz
       */
    eof
    Registry.at('A').docstring.should == 'Foo bar baz'
    Registry.at('B').docstring.should == 'Foo bar baz'
    Registry.at('C').docstring.should == 'Foo bar baz'
    Registry.at('C').type == :module
  end
end
