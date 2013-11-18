require File.dirname(__FILE__) + '/../spec_helper'
require 'stringio'
require 'open-uri'

describe YARD::CLI::Diff do
  before do
    CLI::Yardoc.stub!(:run)
    CLI::Gems.stub!(:run)
    @diff = CLI::Diff.new
  end

  describe 'Argument handling' do
    it "should exit if there is only one gem name" do
      expect(@diff).to receive(:exit)
      expect(log).to receive(:puts).with(/Usage/)
      @diff.run
    end
  end

  describe 'Diffing' do
    before do
      @objects1 = nil
      @objects2 = nil
    end

    def run(*args)
      @all_call = -1
      @data = StringIO.new
      @objects1 ||= %w( C#fooey C#baz D.bar )
      @objects2 ||= %w( A A::B A::B::C A.foo A#foo B C.foo C.bar C#baz )
      @objects = [@objects1, @objects2]
      expect(@diff).to receive(:load_gem_data).ordered.with('gem1') do
        Registry.clear
        YARD.parse_string <<-eof
          class C
            def fooey; end
            def baz; FOO end
          end
          class D
            def self.bar; end
          end
        eof
      end
      expect(@diff).to receive(:load_gem_data).ordered.with('gem2') do
        Registry.clear
        YARD.parse_string <<-eof
          module A
            module B
              class C; end
            end
            def self.foo; end
            def foo; end
          end
          class C
            def self.foo; end
            def self.bar; end
            def baz; BAR end
          end
        eof
      end
      log.stub!(:print) {|data| @data << data }
      log.stub!(:puts) {|*args| @data << args.join("\n"); @data << "\n" }
      @diff.run(*(args + ['gem1', 'gem2']))
    end

    it "should show differences between objects" do
      run
      expect(@data.string).to eq <<-eof
Added objects:

  A ((stdin):1) (...)
  A::B::C ((stdin):3)
  C.bar ((stdin):10)
  C.foo ((stdin):9)

Modified objects:

  C#baz ((stdin):3)

Removed objects:

  C#fooey ((stdin):2)
  D ((stdin):5) (...)

eof
    end

    it "should accept --compact" do
      run('--compact')
      expect(@data.string).to eq <<-eof
A A ((stdin):1) (...)
A A::B::C ((stdin):3)
A C.bar ((stdin):10)
A C.foo ((stdin):9)
M C#baz ((stdin):3)
D C#fooey ((stdin):2)
D D ((stdin):5) (...)
eof
    end

    it "should accept -a/--all" do
      ['-a', '--all'].each do |opt|
        run(opt)
        expect(@data.string).to eq <<-eof
Added objects:

  A ((stdin):1)
  A#foo ((stdin):6)
  A.foo ((stdin):5)
  A::B ((stdin):2)
  A::B::C ((stdin):3)
  C.bar ((stdin):10)
  C.foo ((stdin):9)

Modified objects:

  C#baz ((stdin):3)

Removed objects:

  C#fooey ((stdin):2)
  D ((stdin):5)
  D.bar ((stdin):6)

eof
      end
    end

    it "should accept --compact and --all" do
      run('--compact', '--all')
      expect(@data.string).to eq <<-eof
A A ((stdin):1)
A A#foo ((stdin):6)
A A.foo ((stdin):5)
A A::B ((stdin):2)
A A::B::C ((stdin):3)
A C.bar ((stdin):10)
A C.foo ((stdin):9)
M C#baz ((stdin):3)
D C#fooey ((stdin):2)
D D ((stdin):5)
D D.bar ((stdin):6)
eof
    end

    it "should accept --no-modified" do
      run('--compact', '--no-modified')
      expect(@data.string).to eq <<-eof
A A ((stdin):1) (...)
A A::B::C ((stdin):3)
A C.bar ((stdin):10)
A C.foo ((stdin):9)
D C#fooey ((stdin):2)
D D ((stdin):5) (...)
eof
    end

    it "should accept --query" do
      run('--compact', '--query', 'o.type == :method')
      expect(@data.string).to eq <<-eof
A A#foo ((stdin):6)
A A.foo ((stdin):5)
A C.bar ((stdin):10)
A C.foo ((stdin):9)
M C#baz ((stdin):3)
D C#fooey ((stdin):2)
D D.bar ((stdin):6)
eof
    end
  end

  describe 'File searching' do
    before do
      @diff.stub!(:generate_yardoc)
    end

    it "should search for gem/.yardoc" do
      expect(File).to receive(:directory?).with('gem1/.yardoc').and_return(true)
      expect(File).to receive(:directory?).with('gem2/.yardoc').and_return(true)
      expect(Registry).to receive(:load_yardoc).with('gem1/.yardoc')
      expect(Registry).to receive(:load_yardoc).with('gem2/.yardoc')
      @diff.run('gem1', 'gem2')
    end

    it "should search for argument as yardoc" do
      expect(File).to receive(:directory?).with('gem1/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem2/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem1').and_return(true)
      expect(File).to receive(:directory?).with('gem2').and_return(true)
      expect(Registry).to receive(:load_yardoc).with('gem1')
      expect(Registry).to receive(:load_yardoc).with('gem2')
      @diff.run('gem1', 'gem2')
    end

    it "should search for installed gem" do
      expect(File).to receive(:directory?).with('gem1-1.0.0.gem/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem2-1.0.0/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem1-1.0.0.gem').and_return(false)
      expect(File).to receive(:directory?).with('gem2-1.0.0').and_return(false)
      gemmock = mock(:gemmock)
      spec1 = mock(:spec)
      spec2 = mock(:spec)
      expect(gemmock).to receive(:find_name).at_least(1).times.and_return([spec1, spec2])
      expect(Gem).to receive(:source_index).at_least(1).times.and_return(gemmock)
      spec1.stub!(:full_name).and_return('gem1-1.0.0')
      spec1.stub!(:name).and_return('gem1')
      spec1.stub!(:version).and_return('1.0.0')
      spec2.stub!(:full_name).and_return('gem2-1.0.0')
      spec2.stub!(:name).and_return('gem2')
      spec2.stub!(:version).and_return('1.0.0')
      expect(Registry).to receive(:yardoc_file_for_gem).with('gem1', '= 1.0.0').and_return('/path/to/file')
      expect(Registry).to receive(:yardoc_file_for_gem).with('gem2', '= 1.0.0').and_return(nil)
      expect(Registry).to receive(:load_yardoc).with('/path/to/file')
      expect(CLI::Gems).to receive(:run).with('gem2', '1.0.0').and_return(nil)
      Dir.stub!(:chdir)
      @diff.run('gem1-1.0.0.gem', 'gem2-1.0.0')
    end

    it "should search for .gem file" do
      expect(File).to receive(:directory?).with('gem1/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem2.gem/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem1').and_return(false)
      expect(File).to receive(:directory?).with('gem2.gem').and_return(false)
      expect(File).to receive(:directory?).any_number_of_times
      expect(File).to receive(:exist?).with('gem1.gem').and_return(true)
      expect(File).to receive(:exist?).with('gem2.gem').and_return(true)
      expect(File).to receive(:exist?).any_number_of_times
      expect(File).to receive(:open).with('gem1.gem', 'rb')
      expect(File).to receive(:open).with('gem2.gem', 'rb')
      FileUtils.stub(:mkdir_p)
      Gem::Package.stub(:open)
      FileUtils.stub(:rm_rf)
      @diff.run('gem1', 'gem2.gem')
    end

    it "should search for .gem file on rubygems.org" do
      expect(File).to receive(:directory?).with('gem1/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem2.gem/.yardoc').and_return(false)
      expect(File).to receive(:directory?).with('gem1').and_return(false)
      expect(File).to receive(:directory?).with('gem2.gem').and_return(false)
      expect(File).to receive(:directory?).any_number_of_times
      expect(File).to receive(:exist?).with('gem1.gem').and_return(false)
      expect(File).to receive(:exist?).with('gem2.gem').and_return(false)
      expect(File).to receive(:exist?).any_number_of_times
      expect(@diff).to receive(:open).with('http://rubygems.org/downloads/gem1.gem')
      expect(@diff).to receive(:open).with('http://rubygems.org/downloads/gem2.gem')
      FileUtils.stub(:mkdir_p)
      Gem::Package.stub(:open)
      FileUtils.stub(:rm_rf)
      @diff.run('gem1', 'gem2.gem')
    end

    it "should error if gem is not found" do
      expect(log).to receive(:error).with("Cannot find gem gem1")
      expect(log).to receive(:error).with("Cannot find gem gem2.gem")
      @diff.stub!(:load_gem_data).and_return(false)
      @diff.run('gem1', 'gem2.gem')
    end
  end
end
