# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}VisibilityHandler" do
  before(:all) { parse_file :visibility_handler_001, __FILE__ }

  it "is able to set visibility to public" do
    expect(Registry.at("Testing#pub").visibility).to eq :public
    expect(Registry.at("Testing#pub2").visibility).to eq :public
  end

  it "is able to set visibility to private" do
    expect(Registry.at("Testing#priv").visibility).to eq :private
  end

  it "is able to set visibility to protected" do
    expect(Registry.at("Testing#prot").visibility).to eq :protected
  end

  it "supports parameters and only set visibility on those methods" do
    expect(Registry.at('Testing#notpriv').visibility).to eq :protected
    expect(Registry.at('Testing#notpriv2').visibility).to eq :protected
    expect(Registry.at('Testing#notpriv?').visibility).to eq :protected
  end

  it "only accepts strings and symbols" do
    expect(Registry.at('Testing#name')).to be nil
    expect(Registry.at('Testing#argument')).to be nil
    expect(Registry.at('Testing#method_call')).to be nil
  end

  it "handles constants passed in as symbols" do
    expect(Registry.at('Testing#Foo').visibility).to eq :private
  end

  it "does not register classes with visibility" do
    expect(Registry.at('Testing::Bar').visibility).to eq :public
    expect(Registry.at('Testing::Baz').visibility).to eq :public
  end

  it "can decorate a method definition" do
    expect(Registry.at('Testing#decpriv').visibility).to eq :private
  end unless LEGACY_PARSER

  describe 'ruby 3 specific features' do
    before(:all) { parse_file :visibility_handler_002, __FILE__ }

    it "handles attr_accessor when inlined" do
      expect(Registry.at('Testing#inline_private_attr').visibility).to eq :private
      expect(Registry.at('Testing#inline_private_attr=').visibility).to eq :private
      expect(Registry.at('Testing#inline_protected_writer=').visibility).to eq :protected
      expect(Registry.at('Testing#inline_public_reader').visibility).to eq :public
    end
  end if RUBY_VERSION >= "3."
end
