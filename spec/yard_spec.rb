require File.join(File.dirname(__FILE__), "spec_helper")

describe YARD do
  describe '.load_plugins' do
    it "should load any plugin starting with 'yard_' or 'yard-'" do
      plugins = { 
        'yard' => mock('yard'), 
        'yard_plugin' => mock('yard_plugin'), 
        'yard-plugin' => mock('yard-plugin'),
        'my-yard-plugin' => mock('yard-plugin'),
        'rspec' => mock('rspec'),
      }
      plugins.each do |k, v|
        v.should_receive(:name).at_least(1).times.and_return(k)
      end
      source_mock = mock(:source_index)
      source_mock.should_receive(:entries).and_return(plugins)
      Gem.should_receive(:source_index).and_return(source_mock)
      YARD.should_receive(:require).with('yard_plugin').and_return(true)
      YARD.should_receive(:require).with('yard-plugin').and_return(true)
      log.should_receive(:debug).with(/Loading plugin 'yard_plugin'/).once
      log.should_receive(:debug).with(/Loading plugin 'yard-plugin'/).once
      YARD.load_plugins.should == true
    end
  end
end