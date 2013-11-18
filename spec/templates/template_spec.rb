require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Templates::Template do
  def template(path)
    YARD::Templates::Engine.template!(path, '/full/path/' + path.to_s)
  end

  before :each do
    YARD::Templates::ErbCache.clear!
  end

  describe '.include_parent' do
    it "should not include parent directory if parent directory is a template root path" do
      mod = template('q')
      expect(mod).to_not include(template(''))
    end

    it "should include overridden parent directory" do
      Engine.stub!(:template_paths).and_return(['/foo', '/bar'])
      expect(File).to receive(:directory?).with('/foo/a/b').and_return(true)
      expect(File).to receive(:directory?).with('/bar/a/b').and_return(false)
      expect(File).to receive(:directory?).with('/foo/a').at_least(1).times.and_return(true)
      expect(File).to receive(:directory?).with('/bar/a').at_least(1).times.and_return(true)
      ancestors = Engine.template('a/b').ancestors.map {|c| c.class_name }
      expect(ancestors[0, 3]).to eq %w( Template__foo_a_b Template__bar_a Template__foo_a )
    end

    it "should include parent directory template if exists" do
      mod1 = template('x')
      mod2 = template('x/y')
      expect(mod2).to include(mod1)
    end
  end

  describe '.full_paths' do
    it "should list full_path" do
      mod = template(:a)
      expect(mod.full_paths).to eq ['/full/path/a']
    end

    it "should list paths of included modules" do
      mod = template(:a)
      mod.send(:include, template(:b))
      expect(mod.full_paths).to eq ['/full/path/a', '/full/path/b']
    end

    it "should list paths from modules of included modules" do
      mod = template(:c)
      mod.send(:include, template(:d))
      mod.send(:include, template(:a))
      expect(mod.full_paths).to eq ['c', 'a', 'b', 'd'].map {|o| '/full/path/' + o }
    end

    it "should only list full paths of modules that respond to full_paths" do
      mod = template(:d)
      mod.send(:include, Enumerable)
      expect(mod.full_paths).to eq ['/full/path/d']
    end
  end

  describe '.load_setup_rb' do
    it "should load setup.rb file for module" do
      expect(File).to receive(:file?).with('/full/path/e/setup.rb').and_return(true)
      expect(File).to receive(:read).with('/full/path/e/setup.rb').and_return('def success; end')
      expect(template(:e).new).to respond_to(:success)
    end
  end

  describe '.T' do
    it "should load template from absolute path" do
      mod = template(:a)
      expect(Engine).to receive(:template).with('other')
      mod.T('other')
    end
  end

  describe '.find_file' do
    it "should find file in module's full_path" do
      expect(File).to receive(:file?).with('/full/path/a/basename').and_return(false)
      expect(File).to receive(:file?).with('/full/path/b/basename').and_return(true)
      expect(template(:a).find_file('basename')).to eq '/full/path/b/basename'
    end

    it "should return nil if no file is found" do
      expect(File).to receive(:file?).with('/full/path/a/basename').and_return(false)
      expect(File).to receive(:file?).with('/full/path/b/basename').and_return(false)
      expect(template(:a).find_file('basename')).to be_nil
    end
  end

  describe '.find_nth_file' do
    it "should find 2nd existing file in template paths" do
      expect(File).to receive(:file?).with('/full/path/a/basename').and_return(true)
      expect(File).to receive(:file?).with('/full/path/b/basename').and_return(true)
      expect(template(:a).find_nth_file('basename', 2)).to eq '/full/path/b/basename'
    end

    it "should return nil if no file is found" do
      expect(File).to receive(:file?).with('/full/path/a/basename').and_return(true)
      expect(File).to receive(:file?).with('/full/path/b/basename').and_return(true)
      expect(template(:a).find_nth_file('basename', 3)).to be_nil
    end
  end

  describe '.extra_includes' do
    it "should be included when a module is initialized" do
      module MyModule; end
      Template.extra_includes << MyModule
      expect(template(:e).new).to be_kind_of(MyModule)
    end

    it "should support lambdas in list" do
      module MyModule2; end
      Template.extra_includes << lambda {|opts| MyModule2 if opts.format == :html }
      expect(template(:f).new(:format => :html)).to be_kind_of(MyModule2)
      metaclass = (class << template(:g).new(:format => :text); self end)
      expect(metaclass.ancestors).to_not include(MyModule2)
    end
  end

  describe '.is_a?' do
    it "should be kind of Template" do
      expect(template(:e).is_a?(Template)).to eq true
    end
  end

  describe '#T' do
    it "should delegate to class method" do
      expect(template(:e)).to receive(:T).with('test')
      template(:e).new.T('test')
    end
  end

  describe '#init' do
    it "should be called during initialization" do
      module YARD::Templates::Engine::Template__full_path_e
        def init; sections 1, 2, 3 end
      end
      expect(template(:e).new.sections).to eq Section.new(nil, 1, 2, 3)
    end
  end

  describe '#file' do
    it "should read the file if it exists" do
      expect(File).to receive(:file?).with('/full/path/e/abc').and_return(true)
      expect(IO).to receive(:read).with('/full/path/e/abc').and_return('hello world')
      expect(template(:e).new.file('abc')).to eq 'hello world'
    end

    it "should raise ArgumentError if the file does not exist" do
      expect(File).to receive(:file?).with('/full/path/e/abc').and_return(false)
      expect{ template(:e).new.file('abc') }.to raise_error(ArgumentError)
    end

    it "should replace {{{__super__}}} with inherited template contents if allow_inherited=true" do
      expect(File).to receive(:file?).with('/full/path/a/abc').twice.and_return(true)
      expect(File).to receive(:file?).with('/full/path/b/abc').and_return(true)
      expect(IO).to receive(:read).with('/full/path/a/abc').and_return('foo {{{__super__}}}')
      expect(IO).to receive(:read).with('/full/path/b/abc').and_return('bar')
      expect(template(:a).new.file('abc', true)).to eq "foo bar"
    end

    it "should not replace {{{__super__}}} with inherited template contents if allow_inherited=false" do
      expect(File).to receive(:file?).with('/full/path/a/abc').and_return(true)
      expect(IO).to receive(:read).with('/full/path/a/abc').and_return('foo {{{__super__}}}')
      expect(template(:a).new.file('abc')).to eq "foo {{{__super__}}}"
    end
  end

  describe '#superb' do
    it "should return the inherited erb template contents" do
      expect(File).to receive(:file?).with('/full/path/a/test.erb').and_return(true)
      expect(File).to receive(:file?).with('/full/path/b/test.erb').and_return(true)
      expect(IO).to receive(:read).with('/full/path/b/test.erb').and_return('bar')
      template = template(:a).new
      template.section = :test
      expect(template.superb).to eq "bar"
    end

    it "should work inside an erb template" do
      expect(File).to receive(:file?).with('/full/path/a/test.erb').twice.and_return(true)
      expect(File).to receive(:file?).with('/full/path/b/test.erb').and_return(true)
      expect(IO).to receive(:read).with('/full/path/a/test.erb').and_return('foo<%= superb %>!')
      expect(IO).to receive(:read).with('/full/path/b/test.erb').and_return('bar')
      template = template(:a).new
      template.section = :test
      expect(template.erb(:test)).to eq "foobar!"
    end
  end

  describe '#sections' do
    it "should allow sections to be set if arguments are provided" do
      mod = template(:e).new
      mod.sections 1, 2, [3]
      expect(mod.sections).to eq Section.new(nil, 1, 2, [3])
    end
  end

  describe '#run' do
    it "should render all sections" do
      mod = template(:e).new
      expect(mod).to receive(:render_section).with(Section.new(:a)).and_return('a')
      expect(mod).to receive(:render_section).with(Section.new(:b)).and_return('b')
      expect(mod).to receive(:render_section).with(Section.new(:c)).and_return('c')
      mod.sections :a, :b, :c
      expect(mod.run).to eq 'abc'
    end

    it "should render all sections with options" do
      mod = template(:e).new
      expect(mod).to receive(:render_section).with(Section.new(:a)).and_return('a')
      expect(mod).to receive(:add_options).with(:a => 1).and_yield
      mod.sections :a
      expect(mod.run(:a => 1)).to eq 'a'
    end

    it "should run section list if provided" do
      mod = template(:e).new
      expect(mod).to receive(:render_section).with(Section.new(:q))
      expect(mod).to receive(:render_section).with(Section.new(:x))
      mod.run({}, [:q, :x])
    end

    it "should accept a nil section as empty string" do
      mod = template(:e).new
      expect(mod).to receive(:render_section).with(Section.new(:a))
      mod.sections :a
      expect(mod.run).to eq ""
    end
  end

  describe '#add_options' do
    it "should set instance variables in addition to options" do
      mod = template(:f).new
      mod.send(:add_options, {:a => 1, :b => 2})
      expect(mod.options).to eq ({ :a => 1, :b => 2} )
      expect(mod.instance_variable_get("@a")).to eq 1
      expect(mod.instance_variable_get("@b")).to eq 2
    end

    it "should set instance variables and options only for the block" do
      mod = template(:f).new
      mod.send(:add_options, {:a => 100, :b => 200}) do
        expect(mod.options).to eq ({ :a => 100, :b => 200} )
      end
      expect(mod.options).to_not eq ({:a => 100, :b => 200})
    end
  end

  describe '#render_section' do
    it "should call method if method exists by section name as Symbol" do
      mod = template(:f).new
      expect(mod).to receive(:respond_to?).with(:a).and_return(true)
      expect(mod).to receive(:respond_to?).with('a').and_return(true)
      expect(mod).to receive(:send).with(:a).and_return('a')
      expect(mod).to receive(:send).with('a').and_return('a')
      expect(mod.run({}, [:a, 'a'])).to eq 'aa'
    end

    it "should call erb if no method exists by section name" do
      mod = template(:f).new
      expect(mod).to receive(:respond_to?).with(:a).and_return(false)
      expect(mod).to receive(:respond_to?).with('a').and_return(false)
      expect(mod).to receive(:erb).with(:a).and_return('a')
      expect(mod).to receive(:erb).with('a').and_return('a')
      expect(mod.run({}, [:a, 'a'])).to eq 'aa'
    end

    it "should run a template if section is one" do
      mod2 = template(:g)
      expect(mod2).to receive(:run)
      mod = template(:f).new
      mod.sections mod2
      mod.run
    end

    it "should run a template instance if section is one" do
      mod2 = template(:g).new
      expect(mod2).to receive(:run)
      mod = template(:f).new
      mod.sections mod2
      mod.run
    end
  end

  describe '#yield' do
    it "should yield a subsection" do
      mod = template(:e).new
      mod.sections :a, [:b, :c]
      class << mod
        def a; "(" + yield + ")" end
        def b; "b" end
        def c; "c" end
      end

      expect(mod.run).to eq "(b)"
    end

    it "should yield a subsection within a yielded subsection" do
      mod = template(:e).new
      mod.sections :a, [:b, [:c]]
      class << mod
        def a; "(" + yield + ")" end
        def b; yield end
        def c; "c" end
      end

      expect(mod.run).to eq "(c)"
    end

    it "should support arbitrary nesting" do
      mod = template(:e).new
      mod.sections :a, [:b, [:c, [:d, [:e]]]]
      class << mod
        def a; "(" + yield + ")" end
        def b; yield end
        def c; yield end
        def d; yield end
        def e; "e" end
      end

      expect(mod.run).to eq "(e)"
    end

    it "should yield first two elements if yield is called twice" do
      mod = template(:e).new
      mod.sections :a, [:b, :c, :d]
      class << mod
        def a; "(" + yield + yield + ")" end
        def b; 'b' end
        def c; "c" end
      end

      expect(mod.run).to eq "(bc)"
    end

    it "should ignore any subsections inside subsection yields" do
      mod = template(:e).new
      mod.sections :a, [:b, [:c], :d]
      class << mod
        def a; "(" + yield + yield + ")" end
        def b; 'b' end
        def d; "d" end
      end

      expect(mod.run).to eq "(bd)"
    end

    it "should allow extra options passed via yield" do
      mod = template(:e).new
      mod.sections :a, [:b]
      class << mod
        def a; "(" + yield(:x => "a") + ")" end
        def b; options.x + @x end
      end

      expect(mod.run).to eq "(aa)"
    end
  end

  describe '#yieldall' do
    it "should yield all subsections" do
      mod = template(:e).new
      mod.sections :a, [:b, [:d, [:e]], :c]
      class << mod
        def a; "(" + yieldall + ")" end
        def b; "b" + yieldall end
        def c; "c" end
        def d; 'd' + yieldall end
        def e; 'e' end
      end

      expect(mod.run).to eq "(bdec)"
    end

    it "should yield options to all subsections" do
      mod = template(:e).new
      mod.sections :a, [:b, :c]
      class << mod
        def a; "(" + yieldall(:x => "2") + ")" end
        def b; @x end
        def c; @x end
      end
      expect(mod.run).to eq "(22)"
    end

    it "should yield all subsections more than once" do
      mod = template(:e).new
      mod.sections :a, [:b]
      class << mod
        def a; "(" + yieldall + yieldall + ")" end
        def b; "b" end
      end

      expect(mod.run).to eq "(bb)"
    end

    it "should not yield if no yieldall is called" do
      mod = template(:e).new
      mod.sections :a, [:b]
      class << mod
        def a; "()" end
        def b; "b" end
      end

      expect(mod.run).to eq "()"
    end
  end
end
