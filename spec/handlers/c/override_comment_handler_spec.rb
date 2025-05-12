# frozen_string_literal: true
require "#{File.dirname(__FILE__)}/spec_helper"

RSpec.describe YARD::Handlers::C::OverrideCommentHandler do
  %i(class module).each do |type|
    it "handles Document-#{type}" do
      parse(<<-EOF)
        void something;
        /* Document-#{type}: A
         * Foo bar baz
         */
        void
      EOF
      expect(Registry.at('A').type).to eq type
      expect(Registry.at('A').docstring).to eq 'Foo bar baz'
      expect(Registry.at('A').file).to eq '(stdin)'
      expect(Registry.at('A').line).to eq 2
    end
  end

  it "handles multiple class/module combinations" do
    parse(<<-EOF)
      /* Document-class: A
       * Document-class: B
       * Document-module: C
       * Foo bar baz
       */
    EOF
    expect(Registry.at('A').docstring).to eq 'Foo bar baz'
    expect(Registry.at('B').docstring).to eq 'Foo bar baz'
    expect(Registry.at('C').docstring).to eq 'Foo bar baz'
    expect(Registry.at('C').type).to eq :module
  end

  it "handles Document-class with inheritance" do
    parse(<<-EOF)
      /* Document-class: A < B
       * Foo bar baz
       */
      void
    EOF
    obj = Registry.at('A')
    expect(obj.type).to eq :class
    expect(obj.docstring).to eq 'Foo bar baz'
    expect(obj.superclass).to eq P('B')
  end
end
