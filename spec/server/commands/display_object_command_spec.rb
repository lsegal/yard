require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Server::Commands::DisplayObjectCommand do
  before do
    adapter = mock_adapter
    adapter.document_root = '/c'
    @cmd = DisplayObjectCommand.new(:adapter => adapter)
  end
  
  
  context "#call" do
    
    it "options should return :rdoc as the default markup" do

      mock_request = mock(Object)
      mock_request.stub!(:xhr?).and_return(false)
      mock_request.stub!(:path).and_return("TestFile")
      
      mock_library = mock(Object)
      mock_library.stub!(:source_path).and_return('.')
      @cmd.library = mock_library
      
      @cmd.stub!(:load_yardoc).and_return(nil)
      
      @cmd.incremental = true 
      
      # action
      @cmd.call(mock_request)
      
      # assert
      @cmd.options[:markup].should == :rdoc
    end
    
  end
end