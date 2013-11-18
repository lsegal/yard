require File.dirname(__FILE__) + '/../spec_helper'

class TestYRI < YARD::CLI::YRI
  public :optparse, :find_object, :cache_object
  def test_stub; end
  def print_object(*args) test_stub; super end
end

describe YARD::CLI::YRI do
  before do
    @yri = TestYRI.new
    Registry.stub!(:load)
  end

  describe '#find_object' do
    it "should use cache if available" do
      @yri.stub!(:cache_object)
      expect(File).to receive(:exist?).with('.yardoc').and_return(false)
      expect(File).to receive(:exist?).with('bar.yardoc').and_return(true)
      expect(Registry).to receive(:load).with('bar.yardoc')
      expect(Registry).to receive(:at).ordered.with('Foo').and_return(nil)
      expect(Registry).to receive(:at).ordered.with('Foo').and_return('OBJ')
      @yri.instance_variable_set("@cache", {'Foo' => 'bar.yardoc'})
      expect(@yri.find_object('Foo')).to eq 'OBJ'
    end

    it "should never use cache ahead of current directory's .yardoc" do
      @yri.stub!(:cache_object)
      expect(File).to receive(:exist?).with('.yardoc').and_return(true)
      expect(Registry).to receive(:load).with('.yardoc')
      expect(Registry).to receive(:at).ordered.with('Foo').and_return(nil)
      expect(Registry).to receive(:at).ordered.with('Foo').and_return('OBJ')
      @yri.instance_variable_set("@cache", {'Foo' => 'bar.yardoc'})
      expect(@yri.find_object('Foo')).to eq 'OBJ'
      expect(@yri.instance_variable_get("@search_paths")[0]).to eq '.yardoc'
    end
  end

  describe '#cache_object' do
    it "should skip caching for Registry.yardoc_file" do
      expect(File).to_not receive(:open).with(CLI::YRI::CACHE_FILE, 'w')
      @yri.cache_object('Foo', Registry.yardoc_file)
    end
  end

  describe '#initialize' do
    it "should load search paths" do
      path = %r{/\.yard/yri_search_paths$}
      expect(File).to receive(:file?).with(%r{/\.yard/yri_cache$}).and_return(false)
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:readlines).with(path).and_return(%w(line1 line2))
      @yri = YARD::CLI::YRI.new
      spaths = @yri.instance_variable_get("@search_paths")
      expect(spaths).to include('line1')
      expect(spaths).to include('line2')
    end

    it "should use DEFAULT_SEARCH_PATHS prior to other paths" do
      YARD::CLI::YRI::DEFAULT_SEARCH_PATHS.push('foo', 'bar')
      path = %r{/\.yard/yri_search_paths$}
      expect(File).to receive(:file?).with(%r{/\.yard/yri_cache$}).and_return(false)
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:readlines).with(path).and_return(%w(line1 line2))
      @yri = YARD::CLI::YRI.new
      spaths = @yri.instance_variable_get("@search_paths")
      expect(spaths[0,4]).to eq %w(foo bar line1 line2)
      YARD::CLI::YRI::DEFAULT_SEARCH_PATHS.replace([])
    end
  end

  describe '#run' do
    it "should search for objects and print their documentation" do
      obj = YARD::CodeObjects::ClassObject.new(:root, 'Foo')
      expect(@yri).to receive(:print_object).with(obj)
      @yri.run('Foo')
      Registry.clear
    end

    it "should print usage if no object is provided" do
      expect(@yri).to receive(:print_usage)
      expect(@yri).to receive(:exit).with(1)
      @yri.run('')
    end

    it "should print no documentation exists for object if object is not found" do
      expect(STDERR).to receive(:puts).with("No documentation for `Foo'")
      expect(@yri).to receive(:exit).with(1)
      @yri.run('Foo')
    end

    it "should ensure output is serialized" do
      obj = YARD::CodeObjects::ClassObject.new(:root, 'Foo')
      class << @yri
        def test_stub; @serializer.should_receive(:serialize).once end
      end
      @yri.run('Foo')
    end
  end
end
