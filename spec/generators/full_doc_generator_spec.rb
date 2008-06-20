require File.join(File.dirname(__FILE__), *%w|.. spec_helper|)

describe YARD::Generators::FullDocGenerator do
  def publicize(obj, meth)
    class <<obj; self; end.instance_eval { public meth }
  end

  it "should know about absence of 'readme' file" do
    generator = Generators::FullDocGenerator.new(:readme => nil)
    publicize generator, :readme_file_exists?
    generator.readme_file_exists?.should == false
  end

  it "should know about existence of 'readme' file" do
    generator = Generators::FullDocGenerator.new(:readme => __FILE__)
    publicize generator, :readme_file_exists?
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

    generator.should_receive(:readme_file_exists?).once.and_return(false)
    serializer.should_not_receive(:serialize)

    publicize generator, :generate_readme
    lambda { generator.generate_readme }.should_not raise_error(Errno::ENOENT)
  end
end
