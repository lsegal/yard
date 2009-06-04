require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Rake::YardocTask do
  before do
    Rake.application.clear
  end
  
  def run
    Rake.application.tasks[0].invoke
  end
  
  it "should allow separate rake task name to be set" do
    YARD::Rake::YardocTask.new(:notyardoc)
    Rake.application.tasks[0].name.should == "notyardoc"
  end
  
  it "should allow files to be set" do
    YARD::CLI::Yardoc.should_receive(:run).with('a', 'b', 'c')
    YARD::Rake::YardocTask.new do |t|
      t.files = ['a', 'b', 'c']
    end
    run
  end
  
  it "should allow extra options to be set" do
    YARD::CLI::Yardoc.should_receive(:run).with('--extra', '--opts')
    YARD::Rake::YardocTask.new do |t|
      t.options = ['--extra', '--opts']
    end
    run
  end
  
  it "should allow before callback" do
    proc = lambda { }
    proc.should_receive(:call)
    YARD::CLI::Yardoc.should_receive(:run)
    YARD::Rake::YardocTask.new {|t| t.before = proc }
    run
  end
  
  it "should allow after callback" do
    proc = lambda { }
    proc.should_receive(:call)
    YARD::CLI::Yardoc.should_receive(:run)
    YARD::Rake::YardocTask.new {|t| t.after = proc }
    run
  end
end