# frozen_string_literal: true

describe YARD::CLI::List do
  it "passes command off to Yardoc with --list" do
    expect(YARD::CLI::Yardoc).to receive(:run).with('-c', '--list', '--foo')
    YARD::CLI::List.run('--foo')
  end
end
