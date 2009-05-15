require File.join(File.dirname(__FILE__), *%w|.. spec_helper|)

class YARD::Generators::FullDocGenerator
  public :generate_files, :readme_file_exists? # public for test
end

describe YARD::Generators::FullDocGenerator do
  it "should know about absence of 'readme' file" do
    generator = Generators::FullDocGenerator.new(:readme => nil)
    generator.readme_file_exists?.should == false
  end

  it "should know about existence of 'readme' file" do
    generator = Generators::FullDocGenerator.new(:readme => __FILE__)
    generator.readme_file_exists?.should == true
  end

  it "should allow absence of 'readme' file" do
    serializer = mock('serializer')
    generator_options = {
      :format     => :html,
      :serializer => serializer,
      :readme     => nil
    }
    generator = Generators::FullDocGenerator.new(generator_options)
    serializer.should_not_receive(:serialize)
    lambda { generator.generate_files }.should_not raise_error(Errno::ENOENT)
  end
end
