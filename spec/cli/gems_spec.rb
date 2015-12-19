require File.dirname(__FILE__) + '/../spec_helper'
require 'ostruct'
require 'rubygems'

describe YARD::CLI::Gems do
  before do
    @rebuild = false
    @gem1 = build_mock('gem1')
    @gem2 = build_mock('gem2')
    @gem3 = build_mock('gem3')
  end

  def build_mock(name, version = '1.0')
    OpenStruct.new  :name => name,
                    :version => version,
                    :full_gem_path => "/path/to/gems/#{name}-#{version}",
                    :yardoc_file => "/path/to/yardoc/#{name}-#{version}"
  end

  def build_specs(*specs)
    specs.each do |themock|
      expect(Registry).to receive(:yardoc_file_for_gem).with(themock.name, "= #{themock.version}").and_return(themock.yardoc_file)
      expect(File).to receive(:directory?).with(themock.yardoc_file).and_return(@rebuild)
      expect(File).to receive(:directory?).with(themock.full_gem_path).and_return(true)
      expect(Registry).to receive(:yardoc_file_for_gem).with(themock.name, "= #{themock.version}", true).and_return(themock.yardoc_file)
      expect(Dir).to receive(:chdir).with(themock.full_gem_path)
    end
    expect(Registry).to receive(:clear).exactly(specs.size).times
    expect(CLI::Yardoc).to receive(:run).exactly(specs.size).times
  end

  describe "#run" do
    it "builds all gem indexes if no gem is specified" do
      build_specs(@gem1, @gem2)
      expect(Gem.source_index).to receive(:find_name).with('').and_return([@gem1, @gem2])
      CLI::Gems.run
    end

    it "allows gem to be specified" do
      build_specs(@gem1)
      expect(Gem.source_index).to receive(:find_name).with(@gem1.name, '>= 0').and_return([@gem1])
      CLI::Gems.run(@gem1.name)
    end

    it "allows multiple gems to be specified for building" do
      build_specs(@gem1, @gem2)
      expect(Gem.source_index).to receive(:find_name).with(@gem1.name, @gem1.version).and_return([@gem1])
      expect(Gem.source_index).to receive(:find_name).with(@gem2.name, '>= 0').and_return([@gem2])
      CLI::Gems.run(@gem1.name, @gem1.version, @gem2.name)
    end

    it "allows version to be specified with gem" do
      build_specs(@gem1)
      expect(Gem.source_index).to receive(:find_name).with(@gem1.name, '>= 1.0').and_return([@gem1])
      CLI::Gems.run(@gem1.name, '>= 1.0')
    end

    it "warns if one of the gems is not found, but it should process others" do
      build_specs(@gem2)
      expect(Gem.source_index).to receive(:find_name).with(@gem1.name, '>= 2.0').and_return([])
      expect(Gem.source_index).to receive(:find_name).with(@gem2.name, '>= 0').and_return([@gem2])
      expect(log).to receive(:warn).with(/#{@gem1.name} >= 2.0 could not be found/)
      CLI::Gems.run(@gem1.name, '>= 2.0', @gem2.name)
    end

    it "fails if specified gem(s) is/are not found" do
      expect(CLI::Yardoc).not_to receive(:run)
      expect(Gem.source_index).to receive(:find_name).with(@gem1.name, '>= 2.0').and_return([])
      expect(log).to receive(:warn).with(/#{@gem1.name} >= 2.0 could not be found/)
      expect(log).to receive(:error).with(/No specified gems could be found/)
      CLI::Gems.run(@gem1.name, '>= 2.0')
    end

    it "accepts --rebuild" do
      @rebuild = true
      build_specs(@gem1)
      expect(Gem.source_index).to receive(:find_name).with('').and_return([@gem1])
      CLI::Gems.run('--rebuild')
    end
  end
end
