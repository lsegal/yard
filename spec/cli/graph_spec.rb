require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::Graph do
  it "should serialize output" do
    Registry.should_receive(:load)
    subject.options.serializer.should_receive(:serialize).once
    subject.run
  end

  it "should use the yardoc file specified in .yardopts" do
    YARD::CLI::Yardoc.should_receive(:read_yardoc_db_from_options_file).once.with(no_args)
    Registry.should_receive(:load)
    Templates::Engine.stub :render
    subject.run
  end
end
