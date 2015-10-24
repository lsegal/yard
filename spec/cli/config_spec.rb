require File.dirname(__FILE__) + '/../spec_helper'

require 'yaml'

describe YARD::CLI::Config do
  before do
    @config = YARD::CLI::Config.new
    YARD::Config.options = YARD::Config::DEFAULT_CONFIG_OPTIONS.dup
    allow(YARD::Config).to receive(:save)
  end

  def run(*args)
    @config.run(*args)
  end

  describe "Listing configuration" do
    it "accepts --list" do
      opts = YARD::Config.options
      expect(YAML).to receive(:dump).twice.and_return("--- foo\nbar\nbaz")
      expect(log).to receive(:puts).twice.with("bar\nbaz")
      run
      run('--list')
      expect(YARD::Config.options).to eq opts
    end
  end

  describe "Viewing an item" do
    it "views item if no value is given" do
      YARD::Config.options[:foo] = 'bar'
      expect(log).to receive(:puts).with('"bar"')
      run 'foo'
      expect(YARD::Config.options[:foo]).to eq 'bar'
    end
  end

  describe "Modifying an item" do
    it "accepts --reset to set value" do
      YARD::Config.options[:load_plugins] = 'foo'
      run('--reset', 'load_plugins')
      expect(YARD::Config.options[:load_plugins]).to be false
    end

    it "accepts --as-list to force single item as list" do
      run('--as-list', 'foo', 'bar')
      expect(YARD::Config.options[:foo]).to eq ['bar']
    end

    it "accepts --append to append values to existing key" do
      YARD::Config.options[:foo] = ['bar']
      run('--append', 'foo', 'baz', 'quux')
      expect(YARD::Config.options[:foo]).to eq ['bar', 'baz', 'quux']
      run('-a', 'foo', 'last')
      expect(YARD::Config.options[:foo]).to eq ['bar', 'baz', 'quux', 'last']
    end

    it "turns key into list if --append is used on single item" do
      YARD::Config.options[:foo] = 'bar'
      run('-a', 'foo', 'baz')
      expect(YARD::Config.options[:foo]).to eq ['bar', 'baz']
    end

    it "modifies item if value is given" do
      run('foo', 'xxx')
      expect(YARD::Config.options[:foo]).to eq 'xxx'
    end

    it "turns list of values into array of values" do
      run('foo', 'a', 'b', '1', 'true', 'false')
      expect(YARD::Config.options[:foo]).to eq ['a', 'b', 1, true, false]
    end

    it "turns number into numeric Ruby type" do
      run('foo', '1')
      expect(YARD::Config.options[:foo]).to eq 1
    end

    it "turns true into TrueClass" do
      run('foo', 'true')
      expect(YARD::Config.options[:foo]).to be true
    end

    it "turns false into FalseClass" do
      run('foo', 'false')
      expect(YARD::Config.options[:foo]).to be false
    end

    it "saves on modification" do
      expect(YARD::Config).to receive(:save)
      run('foo', 'true')
    end
  end
end