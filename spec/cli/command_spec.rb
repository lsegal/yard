require File.dirname(__FILE__) + "/../spec_helper"
require 'optparse'

describe YARD::CLI::Command do
  describe '#parse_options' do
    before do
      @options = OptionParser.new
    end
    
    def parse(*args)
      CLI::Command.new.send(:parse_options, @options, args)
    end

    it "should skip unrecognized options but continue to next option" do
      log.should_receive(:warn).with(/Unrecognized.*--list/)
      log.should_receive(:warn).with(/Unrecognized.*--list2/)
      saw_foo = false
      @options.on('--foo') { saw_foo = true }
      parse('--list', '--list2', '--foo')
      saw_foo.should be_true
    end
    
    it "should skip unrecognized options and any extra non-option arg that follows" do
      log.should_receive(:warn).with(/Unrecognized.*--list/)
      saw_foo = false
      @options.on('--foo') { saw_foo = true }
      parse('--list', 'foo', '--foo')
      saw_foo.should be_true
    end
  end
end
