require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::I18n do
  before do
    @i18n = YARD::CLI::I18n.new
    @i18n.use_document_file = false
    @i18n.use_yardopts_file = false
    output_path = File.expand_path(@i18n.options.serializer.basepath)
    File.stub!(:open!).with(output_path, "wb")
    YARD.stub!(:parse)
  end

  describe 'Defaults' do
    before do
      @i18n = YARD::CLI::I18n.new
      @i18n.stub!(:yardopts).and_return([])
      @i18n.stub!(:support_rdoc_document_file!).and_return([])
      @i18n.parse_arguments
    end

    it "should read .yardopts by default" do
      expect(@i18n.use_yardopts_file).to eq true
    end

    it "should use {lib,app}/**/*.rb and ext/**/*.c as default file glob" do
      expect(@i18n.files).to eq ['{lib,app}/**/*.rb', 'ext/**/*.c']
    end

    it "should only show public visibility by default" do
      expect(@i18n.visibilities).to eq [:public]
    end
  end

  describe 'General options' do
    def self.should_accept(*args, &block)
      @counter ||= 0
      @counter += 1
      counter = @counter
      args.each do |arg|
        define_method("test_options_#{@counter}", &block)
        it("should accept #{arg}") { send("test_options_#{counter}", arg) }
      end
    end

    should_accept('--yardopts') do |arg|
      @i18n = YARD::CLI::I18n.new
      @i18n.use_document_file = false
      expect(@i18n).to receive(:yardopts).at_least(1).times.and_return([])
      @i18n.parse_arguments(arg)
      expect(@i18n.use_yardopts_file).to eq true
      @i18n.parse_arguments('--no-yardopts', arg)
      expect(@i18n.use_yardopts_file).to eq true
    end

    should_accept('--yardopts with filename') do |arg|
      @i18n = YARD::CLI::I18n.new
      expect(File).to receive(:read_binary).with('.yardopts_i18n').and_return('')
      @i18n.use_document_file = false
      @i18n.parse_arguments('--yardopts', '.yardopts_i18n')
      expect(@i18n.use_yardopts_file).to eq true
      expect(@i18n.options_file).to eq '.yardopts_i18n'
    end

    should_accept('--no-yardopts') do |arg|
      @i18n = YARD::CLI::I18n.new
      @i18n.use_document_file = false
      expect(@i18n).to_not receive(:yardopts)
      @i18n.parse_arguments(arg)
      expect(@i18n.use_yardopts_file).to eq false
      @i18n.parse_arguments('--yardopts', arg)
      expect(@i18n.use_yardopts_file).to eq false
    end

    should_accept('--exclude') do |arg|
      expect(YARD).to receive(:parse).with(['a'], ['nota', 'b'])
      @i18n.run(arg, 'nota', arg, 'b', 'a')
    end
  end

  describe '.yardopts handling' do
    before do
      @i18n.use_yardopts_file = true
    end

    it "should search for and use yardopts file specified by #options_file" do
      expect(File).to receive(:read_binary).with("test").and_return("-o \n\nMYPATH\nFILE1 FILE2")
      @i18n.use_document_file = false
      @i18n.options_file = "test"
      expect(File).to receive(:open!).with(File.expand_path("MYPATH"), "wb")
      @i18n.run
      expect(@i18n.files).to eq ["FILE1", "FILE2"]
    end
  end

  describe '#run' do
    it "should parse_arguments if run() is called" do
      expect(@i18n).to receive(:parse_arguments)
      @i18n.run
    end

    it "should parse_arguments if run(arg1, arg2, ...) is called" do
      expect(@i18n).to receive(:parse_arguments)
      @i18n.run('--private', '-p', 'foo')
    end

    it "should not parse_arguments if run(nil) is called" do
      expect(@i18n).to_not receive(:parse_arguments)
      @i18n.run(nil)
    end
  end
end
