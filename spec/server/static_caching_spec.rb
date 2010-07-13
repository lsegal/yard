require File.dirname(__FILE__) + '/../spec_helper'
require 'ostruct'

describe YARD::Server::StaticCaching do
  include Server::StaticCaching
  
  describe '#check_static_cache' do
    def adapter; @adapter ||= OpenStruct.new end
    def request; @request ||= OpenStruct.new end

    def setup(path)
      adapter.document_root = '/public'
      request.path = path
    end
    
    it "should return nil if document root is not set" do
      check_static_cache.should be_nil
    end
    
    it "should read a file from document root if path matches file on system" do
      setup('/hello/world.html')
      File.should_receive(:file?).with('/public/hello/world.html').and_return(true)
      File.should_receive(:open).with('/public/hello/world.html', anything).and_return('body')
      s, h, b = *check_static_cache
      s.should == 200
      b.should == ["body"]
    end
    
    it "should read a file if path matches file on system + .html" do
      setup('/hello/world')
      File.should_receive(:file?).with('/public/hello/world.html').and_return(true)
      File.should_receive(:open).with('/public/hello/world.html', anything).and_return('body')
      s, h, b = *check_static_cache
      s.should == 200
      b.should == ["body"]
    end
    
    it "should return nil if no matching file is found" do
      setup('/hello/foo')
      File.should_receive(:file?).with('/public/hello/foo.html').and_return(false)
      check_static_cache.should == nil
    end
  end
end