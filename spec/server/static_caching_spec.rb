require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Server::StaticCaching do
  include StaticCaching

  describe "#check_static_cache" do
    def adapter; @adapter ||= mock_adapter end
    def request; @request ||= OpenStruct.new end

    it "returns nil if document root is not set" do
      adapter.document_root = nil
      expect(check_static_cache).to be nil
    end

    it "reads a file from document root if path matches file on system" do
      request.path = '/hello/world.html'
      expect(File).to receive(:file?).with('/public/hello/world.html').and_return(true)
      expect(File).to receive(:open).with('/public/hello/world.html', anything).and_return('body')
      s, h, b = *check_static_cache
      expect(s).to eq 200
      expect(b).to eq ["body"]
    end

    it "reads a file if path matches file on system + .html" do
      request.path = '/hello/world'
      expect(File).to receive(:file?).with('/public/hello/world.html').and_return(true)
      expect(File).to receive(:open).with('/public/hello/world.html', anything).and_return('body')
      s, h, b = *check_static_cache
      expect(s).to eq 200
      expect(b).to eq ["body"]
    end

    it "returns nil if no matching file is found" do
      request.path = '/hello/foo'
      expect(File).to receive(:file?).with('/public/hello/foo.html').and_return(false)
      expect(check_static_cache).to eq nil
    end
  end
end