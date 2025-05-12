# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::CodeObjects::ConstantObject do
  before do
    Registry.clear
  end

  describe "#target" do
    it "resolves" do
        const1 = ConstantObject.new(:root, :A)
        const2 = ConstantObject.new(:root, :B)
        const2.value = "A"
        expect(const2.target).to eq const1
    end

    it "returns nil for an integer value" do
        const = ConstantObject.new(:root, :A)
        const.value = "1"
        expect(const.target).to be_nil
    end

    it "returns nil for a string value" do
        const = ConstantObject.new(:root, :A)
        const.value = '"String"'
        expect(const.target).to be_nil
    end

    it "returns nil for an empty value" do
        const = ConstantObject.new(:root, :A)
        const.value = ""
        expect(const.target).to be_nil
    end

    it "returns nil for an explicit self-referential constant" do
        const = ConstantObject.new(:root, :A)
        const.value = "A"
        expect(const.target).to be_nil
    end

    it "returns nil for an explicit self-referential constant" do
        mod = ModuleObject.new(:root, :M)
        const = ConstantObject.new(mod, :A)
        const.value = "self"
        expect(const.target).to be_nil
    end
  end
end
