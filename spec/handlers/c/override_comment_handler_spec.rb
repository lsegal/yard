require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Handlers::C::OverrideCommentHandler do
  [:class, :module].each do |type|
    it "should handle Document-#{type}" do
      parse(<<-eof)
        void something;
        /* Document-#{type}: A
         * Foo bar baz
         */
        void
      eof
      expect(Registry.at('A').type).to eq type
      expect(Registry.at('A').docstring).to eq 'Foo bar baz'
      expect(Registry.at('A').file).to eq '(stdin)'
      expect(Registry.at('A').line).to eq 2
    end
  end

  it "should handle multiple class/module combinations" do
    parse(<<-eof)
      /* Document-class: A
       * Document-class: B
       * Document-module: C
       * Foo bar baz
       */
    eof
    expect(Registry.at('A').docstring).to eq 'Foo bar baz'
    expect(Registry.at('B').docstring).to eq 'Foo bar baz'
    expect(Registry.at('C').docstring).to eq 'Foo bar baz'
    Registry.at('C').type == :module
  end

  it "should handle Document-class with inheritance" do
    parse(<<-eof)
      /* Document-class: A < B
       * Foo bar baz
       */
      void
    eof
    obj = Registry.at('A')
    expect(obj.type).to eq :class
    expect(obj.docstring).to eq 'Foo bar baz'
    expect(obj.superclass).to eq P('B')
  end
end
