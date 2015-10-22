require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{LEGACY_PARSER ? "Legacy::" : ""}PrivateClassMethodHandler" do
  before(:all) { parse_file :private_class_method_handler_001, __FILE__ }

  it "handles private_class_method statement" do
    expect(Registry.at('A.c').visibility).to eq :private
    expect(Registry.at('A.d').visibility).to eq :private
    expect(Registry.at('A.e').visibility).to eq :private
  end

  it "fails if parameter is not String or Symbol" do
    undoc_error 'class Foo; X = 1; private_class_method X.new("hi"); end'
    undoc_error 'class Foo; X = 1; private_class_method 123; end'
  end unless LEGACY_PARSER

  # Issue #760
  # https://github.com/lsegal/yard/issues/760
  it "handles singleton classes" do
    # Note: It's important to def a method within the singleton class or
    #       the bug may not trigger.
    code = 'class SingletonClass; private_class_method :new; def self.foo; "foo"end; end'
    StubbedSourceParser.parse_string(code) # Should be successful.
  end unless LEGACY_PARSER
  
  
  describe "handles reopened class" do
    
    # Modified #parse_file from '/spec/spec_helper.rb' because the second example
    # file was overwriting the data from the first example when trying to reopen
    # the class.
    def parse_files(files, thisfile = __FILE__, log_level = log.level, ext = '.rb.txt')
      Registry.clear
      paths = files.map { |file| File.join(File.dirname(thisfile), 'examples', file.to_s + ext) }
      YARD::Parser::SourceParser.parse(paths, [], log_level)
    end
    
    before {
      parse_files [
        :private_class_method_handler_002,
        :private_class_method_handler_003
      ], __FILE__
    }
    
    specify do
      expect(Registry.at('SingletonClass.foo').visibility).to eq :public
      expect(Registry.at('SingletonClass.bar').visibility).to eq :private
      expect(Registry.at('SingletonClass.baz').visibility).to eq :private
      expect(Registry.at('SingletonClass.bat').visibility).to eq :public
    end
    
  end unless LEGACY_PARSER # reopened class
end
