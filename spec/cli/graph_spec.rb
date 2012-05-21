require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::Yardoc do
  it "should serialize output" do
    Registry.should_receive(:load)
    @graph = YARD::CLI::Graph.new
    @graph.options.serializer.should_receive(:serialize).once
    @graph.run
  end
end
