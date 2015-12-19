require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Server::Commands::StaticFileCommand do
  before do
    adapter = mock_adapter
    adapter.document_root = '/c'
    @cmd = StaticFileCommand.new(:adapter => adapter)
  end

  describe "#run" do
    def run(path, status = nil, body = nil)
      s, h, b = *@cmd.call(mock_request(path))
      expect(body).to eq b.first if body
      expect(status).to eq s if status
      [s, h, b]
    end

    it "searches through document root before static paths" do
      expect(File).to receive(:exist?).with('/c/path/to/file.txt').ordered.and_return(false)
      StaticFileCommand::STATIC_PATHS.reverse.each do |path|
        expect(File).to receive(:exist?).with(File.join(path, 'path/to/file.txt')).ordered.and_return(false)
      end
      run '/path/to/file.txt'
    end

    it "returns file contents if found" do
      tpl = Templates::Engine.template(:default, :fulldoc, :html)
      expect(File).to receive(:exist?).with('/c/path/to/file.txt').and_return(false)
      expect(tpl).to receive(:find_file).with('/path/to/file.txt').and_return('/path/to/foo')
      expect(File).to receive(:read).with('/path/to/foo').and_return('FOO')
      run('/path/to/file.txt', 200, 'FOO')
    end

    it "allows registering of new paths and use those before other static paths" do
      Server.register_static_path '/foo'
      path = '/foo/path/to/file.txt'
      expect(File).to receive(:exist?).with('/c/path/to/file.txt').and_return(false)
      expect(File).to receive(:exist?).with(path).and_return(true)
      expect(File).to receive(:read).with(path).and_return('FOO')
      run('/path/to/file.txt', 200, 'FOO')
    end

    it "does not use registered path before docroot" do
      Server.register_static_path '/foo'
      path = '/foo/path/to/file.txt'
      expect(File).to receive(:exist?).with('/c/path/to/file.txt').and_return(true)
      expect(File).to receive(:read).with('/c/path/to/file.txt').and_return('FOO')
      run('/c/path/to/file.txt', 200, 'FOO')
    end

    it "returns 404 if not found" do
      expect(File).to receive(:exist?).with('/c/path/to/file.txt').ordered.and_return(false)
      StaticFileCommand::STATIC_PATHS.reverse.each do |path|
        expect(File).to receive(:exist?).with(File.join(path, 'path/to/file.txt')).ordered.and_return(false)
      end
      run('/path/to/file.txt', 404)
    end

    it "returns text/html for file with no extension" do
      expect(File).to receive(:exist?).with('/c/file').and_return(true)
      expect(File).to receive(:read).with('/c/file')
      s, h, b = *run('/file')
      expect(h['Content-Type']).to eq 'text/html'
    end

    {
      "js" => "text/javascript",
      "css" => "text/css",
      "png" => "image/png",
      "gif" => "image/gif",
      "htm" => "text/html",
      "html" => "text/html",
      "txt" => "text/plain",
      "unknown" => "application/octet-stream"
    }.each do |ext, mime|
      it "serves file.#{ext} as #{mime}" do
        expect(File).to receive(:exist?).with('/c/file.' + ext).and_return(true)
        expect(File).to receive(:read).with('/c/file.' + ext)
        s, h, b = *run('/file.' + ext)
        expect(h['Content-Type']).to eq mime
      end
    end
  end
end