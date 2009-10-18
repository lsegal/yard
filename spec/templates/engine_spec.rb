require File.dirname(__FILE__) + '/spec_helper'

describe Engine do
  describe '.register_template_path' do
    it "should register a String path" do
      Engine.register_template_path('.')
      Engine.template_paths.last.should == Pathname.new('.')
      Engine.template_paths.pop
    end
    
    it "should register a Pathname path" do
      Engine.register_template_path(Pathname.new('.'))
      Engine.template_paths.last.should == Pathname.new('.')
      Engine.template_paths.pop
    end
  end
  
  describe '.template!' do
    it "should create a module including Template" do
      mod = Engine.template!('path/to/template')
      mod.should include(Template)
      mod.full_path.to_s.should == 'path/to/template'
    end
    
    it "should create a module including Template with full_path" do
      mod = Engine.template!('path/to/template2', '/full/path/to/template2')
      mod.should include(Template)
      mod.full_path.to_s.should == '/full/path/to/template2'
    end
  end
  
  describe '.template' do
    it "should raise an error if the template is not found" do
      lambda { Engine.template(:a, :b, :c) }.should raise_error(ArgumentError)
    end
    
    it "should create a module including Template" do
      mock = mock(:template)
      Engine.should_receive(:find_template_paths).with(nil, 'template/name').and_return(['/full/path/template/name'])
      Engine.should_receive(:template!).with('template/name', '/full/path/template/name').and_return(mock)
      Engine.template('template/name').should == mock
    end
    
    it "should create a Template from a relative Template path" do
      Engine.should_receive(:template_paths).and_return([])
      FileTest.should_receive(:directory?).with("/full/path/template/notname").and_return(true)
      start_template = mock(:start_template)
      start_template.stub!(:full_path).and_return(Pathname.new('/full/path/template/name'))
      start_template.stub!(:full_paths).and_return([Pathname.new('/full/path/template/name')])
      start_template.should_receive(:is_a?).with(Template).and_return(true)
      mod = Engine.template(start_template, '..', 'notname')
      mod.should include(Template)
      mod.full_path.to_s.should == "/full/path/template/notname"
    end

    it "should create a Template including other matching templates in path" do
      mock1, mock2 = mock(:template1), mock(:template2)
      paths = ['/full/path/template/name', '/full/path2/template/name']
      Engine.should_receive(:find_template_paths).with(nil, 'template/name').and_return(paths)
      Engine.should_receive(:template!).with('template/name', '/full/path/template/name').and_return(mock1)
      Engine.should_receive(:template!).with('template/name', '/full/path2/template/name').and_return(mock2)
      mock1.should_receive(:include).with(mock2)
      Engine.template('template/name').should == mock1
    end
  end
  
  describe '.generate' do
    it "should generate with fulldoc template" do
      mod = mock(:template)
      mod.should_receive(:run).with(:format => :text, :template => :default, :objects => [:a, :b, :c])
      Engine.should_receive(:template).with(:default, :fulldoc, :text).and_return(mod)
      Engine.generate([:a, :b, :c])
    end
  end
  
  describe '.render' do
    def loads_template(*args)
      Engine.should_receive(:template).with(*args).and_return(@template)
    end
  
    before(:all) do 
      @template = mock(:template)
      @template.stub!(:include)
      @object = CodeObjects::MethodObject.new(:root, :method)
    end
  
    it "should accept method call with no parameters" do
      loads_template(:default, :method, :text)
      @template.should_receive(:run).with :type => :method,
                                          :template => :default,
                                          :format => :text,
                                          :object => @object
      @object.format
    end
  
    it "should allow template key to be changed" do
      loads_template(:javadoc, :method, :text)
      @template.should_receive(:run).with :type => :method,
                                          :template => :javadoc,
                                          :format => :text,
                                          :object => @object
      @object.format(:template => :javadoc)
    end

    it "should allow type key to be changed" do
      loads_template(:default, :fulldoc, :text)
      @template.should_receive(:run).with :type => :fulldoc,
                                          :template => :default,
                                          :format => :text,
                                          :object => @object
      @object.format(:type => :fulldoc)
    end
  
    it "should allow format key to be changed" do
      loads_template(:default, :method, :html)
      @template.should_receive(:run).with :type => :method,
                                          :template => :default,
                                          :format => :html,
                                          :object => @object
      @object.format(:format => :html)
    end
  end
end
