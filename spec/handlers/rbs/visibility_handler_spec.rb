# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::VisibilityHandler do
  before do
    parse_rbs <<-RBS
module Greeter
  def self?.both: () -> String
  public def shown: () -> String
  private def hidden: () -> String
  private attr_reader secret: String

  private

  def after_private: () -> String
  attr_accessor later: Integer
  def self.singleton: () -> String
end

class Other
  def open: () -> void
end
    RBS
  end

  it "registers members with a visibility modifier" do
    expect(Registry.at('Greeter#shown').visibility).to eq :public
    expect(Registry.at('Greeter#hidden').visibility).to eq :private
    expect(Registry.at('Greeter#secret').visibility).to eq :private
  end

  it "applies a visibility section to the instance members after it" do
    expect(Registry.at('Greeter#after_private').visibility).to eq :private
    expect(Registry.at('Greeter#later').visibility).to eq :private
    expect(Registry.at('Greeter#later=').visibility).to eq :private
    expect(Registry.at('Greeter.singleton').visibility).to eq :public
  end

  it "does not carry a visibility section into the next namespace" do
    expect(Registry.at('Other#open').visibility).to eq :public
  end

  it "registers self? methods as module functions" do
    expect(Registry.at('Greeter.both').visibility).to eq :public
    expect(Registry.at('Greeter.both').tag(:return).types).to eq ['String']
    expect(Registry.at('Greeter#both').visibility).to eq :private
    expect(Registry.at('Greeter#both').tag(:return).types).to eq ['String']
  end
end
