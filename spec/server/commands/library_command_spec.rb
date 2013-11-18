require File.dirname(__FILE__) + '/../spec_helper'
require 'ostruct'

describe YARD::Server::Commands::LibraryCommand do
  before do
    Templates::Engine.stub!(:render)
    Templates::Engine.stub!(:generate)
    YARD.stub!(:parse)
    Registry.stub!(:load)
    Registry.stub!(:save)

    @cmd = LibraryCommand.new(:adapter => mock_adapter)
    @request = OpenStruct.new(:xhr? => false, :path => "/foo")
    @library = OpenStruct.new(:source_path => '.')
    @cmd.library = @library
    @cmd.stub!(:load_yardoc).and_return(nil)
  end

  def call
    expect{ @cmd.call(@request) }.to raise_error(NotImplementedError)
  end

  describe "#call" do
    it "should raise NotImplementedError" do
      call
    end

    it "should set :rdoc as the default markup in incremental mode" do
      @cmd.incremental = true
      call
      expect(@cmd.options[:markup]).to eq :rdoc
    end

    it "should set :rdoc as the default markup in regular mode" do
      call
      expect(@cmd.options[:markup]).to eq :rdoc
    end
  end
end
