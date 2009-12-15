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
      source_mock.should_receive(:find_name).with('').and_return(plugins.values)
      Gem.should_receive(:source_index).and_return(source_mock)
      YARD.should_receive(:require).with('yard_plugin').and_return(true)
      YARD.should_receive(:require).with('yard-plugin').and_return(true)
      log.should_receive(:debug).with(/Loading plugin 'yard_plugin'/).once
      log.should_receive(:debug).with(/Loading plugin 'yard-plugin'/).once
      YARD.load_plugins.should == true
    end
    
    it "should ignore any plugins specified in '~/.yard/ignored_plugins'" do
      path = File.expand_path("~/.yard/ignored_plugins")
      plugins = { 
        'yard-plugin' => mock('yard-plugin'),
        'yard-plugin2' => mock('yard-plugin2'),
        'yard-plugin3' => mock('yard-plugin3'),
      }
      plugins.each do |k, v|
        v.should_receive(:name).at_least(1).times.and_return(k)
      end
      source_mock = mock(:source_index)
      source_mock.should_receive(:find_name).with('').and_return(plugins.values)
      File.should_receive(:file?).with(path).and_return(true)
      IO.should_receive(:read).with(path).and_return('yard-plugin yard-plugin2')
      Gem.should_receive(:source_index).and_return(source_mock)
      YARD.should_receive(:require).with('yard-plugin3').and_return(true)
      log.should_receive(:debug).with(/Loading plugin 'yard-plugin3'/).once
      YARD.load_plugins.should == true
    end
    
    it "should not load plugins starting with yard-doc-" do
      mock = mock('yard-doc-core')
      mock.should_receive(:name).at_least(1).times.and_return('yard-doc-core')
      Gem.source_index.should_receive(:find_name).with('').and_return([mock])
      YARD.should_not_receive(:require)
      YARD.load_plugins.should == true
    end
  end
end