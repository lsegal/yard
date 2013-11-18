require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::Rake::YardocTask do
  before do
    @yardoc = YARD::CLI::Yardoc.new
    @yardoc.statistics = false
    @yardoc.use_document_file = false
    @yardoc.use_yardopts_file = false
    @yardoc.generate = false
    Templates::Engine.stub!(:render)
    Templates::Engine.stub!(:generate)
    YARD.stub!(:parse)
    Registry.stub!(:load)
    Registry.stub!(:save)
    YARD::CLI::Yardoc.stub!(:new).and_return(@yardoc)
    ::Rake.application.clear
  end

  def run
    ::Rake.application.tasks[0].invoke
  end

  describe '#initialize' do
    it "should allow separate rake task name to be set" do
      YARD::Rake::YardocTask.new(:notyardoc)
      expect(::Rake.application.tasks[0].name).to eq "notyardoc"
    end
  end

  describe '#files' do
    it "should allow files to be set" do
      YARD::Rake::YardocTask.new do |t|
        t.files = ['a', 'b', 'c']
      end
      run
      expect(@yardoc.files).to eq %w(a b c)
    end
  end

  describe '#options' do
    it "should allow extra options to be set" do
      YARD::Rake::YardocTask.new do |t|
        t.options = ['--private', '--protected']
      end
      run
      expect(@yardoc.visibilities).to eq [:public, :private, :protected]
    end

    it "should allow --api and --no-api" do
      YARD::Rake::YardocTask.new do |t|
        t.options = %w(--api public --no-api)
      end
      run
      @yardoc.options.verifier.expressions.
        should include('["public"].include?(@api.text) || !@api')
    end
  end

  describe '#before' do
    it "should allow before callback" do
      proc = lambda { }
      expect(proc).to receive(:call)
      expect(@yardoc).to receive(:run)
      YARD::Rake::YardocTask.new {|t| t.before = proc }
      run
    end
  end

  describe '#after' do
    it "should allow after callback" do
      proc = lambda { }
      expect(proc).to receive(:call)
      expect(@yardoc).to receive(:run)
      YARD::Rake::YardocTask.new {|t| t.after = proc }
      run
    end
  end

  describe '#verifier' do
    it "should allow a verifier proc to be set" do
      verifier = Verifier.new
      expect(@yardoc).to receive(:run) do
        expect(@yardoc.options[:verifier]).to eq verifier
      end
      YARD::Rake::YardocTask.new {|t| t.verifier = verifier }
      run
    end

    it "should override --query options" do
      verifier = Verifier.new
      expect(@yardoc).to receive(:run) do
        expect(@yardoc.options[:verifier]).to eq verifier
      end
      YARD::Rake::YardocTask.new do |t|
        t.options += ['--query', '@return']
        t.verifier = verifier
      end
      run
    end
  end
end
