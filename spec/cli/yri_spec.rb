require File.dirname(__FILE__) + '/../spec_helper'

class YARD::CLI::YRI
  public :optparse, :find_object, :cache_object
end

describe YARD::CLI::Yardoc do
  before do
    @yri = YARD::CLI::YRI.new
    Registry.instance.stub!(:load)
  end
  
  describe '#find_object' do
    it "should use cache if available" do
      @yri.stub!(:cache_object)
      Registry.should_receive(:load).with('bar.yardoc')
      Registry.should_receive(:at).with('Foo').and_return('OBJ')
      @yri.instance_variable_set("@cache", {'Foo' => 'bar.yardoc'})
      @yri.find_object('Foo').should == 'OBJ'
      @yri.instance_variable_get("@search_paths")[0].should == 'bar.yardoc'
    end
  end
  
  describe '#cache_object' do
    it "should skip caching for Registry.yardoc_file" do
      File.should_not_receive(:open).with(CLI::YRI::CACHE_FILE, 'w')
      @yri.cache_object('Foo', Registry.yardoc_file)
    end
  end
end
