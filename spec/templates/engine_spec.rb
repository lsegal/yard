require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Templates::Engine do
  describe '.register_template_path' do
    it "should register a String path" do
      Engine.register_template_path('.')
      expect(Engine.template_paths.pop).to eq '.'
    end
  end

  describe '.template!' do
    it "should create a module including Template" do
      mod = Engine.template!('path/to/template')
      expect(mod).to include(Template)
      expect(mod.full_path.to_s).to eq 'path/to/template'
    end

    it "should create a module including Template with full_path" do
      mod = Engine.template!('path/to/template2', '/full/path/to/template2')
      expect(mod).to include(Template)
      expect(mod.full_path.to_s).to eq '/full/path/to/template2'
    end
  end

  describe '.template' do
    it "should raise an error if the template is not found" do
      expect{ Engine.template(:a, :b, :c) }.to raise_error(ArgumentError)
    end

    it "should create a module including Template" do
      mock = mock(:template)
      expect(Engine).to receive(:find_template_paths).with(nil, 'template/name').and_return(['/full/path/template/name'])
      expect(Engine).to receive(:template!).with('template/name', ['/full/path/template/name']).and_return(mock)
      expect(Engine.template('template/name')).to eq mock
    end

    it "should create a Template from a relative Template path" do
      expect(Engine).to receive(:template_paths).and_return([])
      expect(File).to receive(:directory?).with("/full/path/template/notname").and_return(true)
      start_template = mock(:start_template)
      start_template.stub!(:full_path).and_return('/full/path/template/name')
      start_template.stub!(:full_paths).and_return(['/full/path/template/name'])
      expect(start_template).to receive(:is_a?).with(Template).and_return(true)
      mod = Engine.template(start_template, '..', 'notname')
      expect(mod).to include(Template)
      expect(mod.full_path.to_s).to eq "/full/path/template/notname"
    end

    it "should create a Template including other matching templates in path" do
      paths = ['/full/path/template/name', '/full/path2/template/name']
      expect(Engine).to receive(:find_template_paths).with(nil, 'template').at_least(1).times.and_return([])
      expect(Engine).to receive(:find_template_paths).with(nil, 'template/name').and_return(paths)
      ancestors = Engine.template('template/name').ancestors.map {|m| m.class_name }
      expect(ancestors).to include("Template__full_path2_template_name")
    end

    it "should include parent directories before other template paths" do
      paths = ['/full/path/template/name', '/full/path2/template/name']
      expect(Engine).to receive(:find_template_paths).with(nil, 'template/name').and_return(paths)
      ancestors = Engine.template('template/name').ancestors.map {|m| m.class_name }
      expect(ancestors[0, 4]).to eq ["Template__full_path_template_name", "Template__full_path_template",
        "Template__full_path2_template_name", "Template__full_path2_template"]
    end
  end

  describe '.generate' do
    it "should generate with fulldoc template" do
      mod = mock(:template)
      options = TemplateOptions.new
      options.reset_defaults
      options.objects = [:a, :b, :c]
      options.object = Registry.root
      expect(mod).to receive(:run).with(options)
      expect(Engine).to receive(:template).with(:default, :fulldoc, :text).and_return(mod)
      Engine.generate([:a, :b, :c])
    end
  end

  describe '.render' do
    def loads_template(*args)
      expect(Engine).to receive(:template).with(*args).and_return(@template)
    end

    before(:all) do
      @object = CodeObjects::MethodObject.new(:root, :method)
    end

    before do
      @options = TemplateOptions.new
      @options.reset_defaults
      @options.object = @object
      @options.type = @object.type
      @template = mock(:template)
      @template.stub!(:include)
      expect(@template).to receive(:run).with(@options)
    end

    it "should accept method call with no parameters" do
      loads_template(:default, :method, :text)
      @object.format
    end

    it "should allow template key to be changed" do
      loads_template(:javadoc, :method, :text)
      @options.template = :javadoc
      @object.format(:template => :javadoc)
    end

    it "should allow type key to be changed" do
      loads_template(:default, :fulldoc, :text)
      @options.type = :fulldoc
      @object.format(:type => :fulldoc)
    end

    it "should allow format key to be changed" do
      loads_template(:default, :method, :html)
      @options.format = :html
      @object.format(:format => :html)
    end
  end
end
