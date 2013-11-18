require File.dirname(__FILE__) + "/spec_helper"

describe YARD::Server do
  describe '.register_static_path' do
    it "should register a static path" do
      YARD::Server.register_static_path 'foo'
      expect(YARD::Server::Commands::StaticFileCommand::STATIC_PATHS.last).to eq "foo"
    end
  end
end