require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Rake::YardocTask do
  before do
    @yardoc = mock(:cli)
    YARD::CLI::Yardoc.stub!(:new).and_return(@yardoc)
    Rake.application.clear
  end
  
  def run
    Rake.application.tasks[0].invoke
  end
  
  describe '#initialize' do
    it "should allow separate rake task name to be set" do
      YARD::Rake::YardocTask.new(:notyardoc)
      Rake.application.tasks[0].name.should == "notyardoc"
    end
  end
  
  describe '#files' do
    it "should allow files to be set" do
      @yardoc.should_receive(:run).with('a', 'b', 'c')
      YARD::Rake::YardocTask.new do |t|
        t.files = ['a', 'b', 'c']
      end
      run
    end
  end
  
  describe '#options' do
    it "should allow extra options to be set" do
      @yardoc.should_receive(:run).with('--extra', '--opts')
      YARD::Rake::YardocTask.new do |t|
        t.options = ['--extra', '--opts']
      end
      run
    end
  end
  
  describe '#before' do
    it "should allow before callback" do
      proc = lambda { }
      proc.should_receive(:call)
      @yardoc.should_receive(:run)
      YARD::Rake::YardocTask.new {|t| t.before = proc }
      run
    end
  end
  
  describe '#after' do
    it "should allow after callback" do
      proc = lambda { }
      proc.should_receive(:call)
      @yardoc.should_receive(:run)
      YARD::Rake::YardocTask.new {|t| t.after = proc }
      run
    end
    
    describe '#verifier' do
      it "should allow a verifier proc to be set" do
        proc = mock(:proc)
        mockopts = mock(:options)
        mockopts.should_receive(:[]=).with(:verifier, proc)
        @yardoc.should_receive(:options).and_return(mockopts)
        @yardoc.should_receive(:run)
        YARD::Rake::YardocTask.new {|t| t.verifier = proc }
        run
      end

      it "should only use verifier if no --query options are passed" do
        proc = mock(:proc)
        mockopts = mock(:options)
        mockopts.should_receive(:[]=).with(:verifier, proc)
        @yardoc.should_receive(:options).and_return(mockopts)
        @yardoc.should_receive(:run)
        YARD::Rake::YardocTask.new do |t| 
          t.options += ['--query', '@return']
          t.verifier = proc
        end
        run
      end
    end
  end
end