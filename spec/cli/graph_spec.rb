require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::Graph do
  it "should serialize output" do
    expect(Registry).to receive(:load).at_least(1).times
    subject.stub(:yardopts) { [] }
    expect(subject.options.serializer).to receive(:serialize).once
    subject.run
  end

  it 'should read yardoc file from .yardopts' do
    subject.stub(:yardopts) { %w(--db /path/to/db) }
    expect(subject.options.serializer).to receive(:serialize).once
    subject.run
    expect(Registry.yardoc_file).to eq '/path/to/db'
  end
end
