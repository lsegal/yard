# frozen_string_literal: true
require File.dirname(__FILE__) + '/spec_helper'

RSpec.describe YARD::Handlers::RBS::MethodHandler do
  it "registers an instance method" do
    parse_rbs <<-RBS
class Foo
  def greet: () -> void
end
    RBS
    expect(Registry.at('Foo#greet')).to be_a(CodeObjects::MethodObject)
  end

  it "registers a class method" do
    parse_rbs <<-RBS
class Foo
  def self.build: () -> Foo
end
    RBS
    expect(Registry.at('Foo.build')).to be_a(CodeObjects::MethodObject)
  end

  it "adds a @return tag from the RBS signature" do
    parse_rbs <<-RBS
class Foo
  def name: () -> String
end
    RBS
    obj = Registry.at('Foo#name')
    expect(obj.tag(:return).types).to eq ['String']
  end

  it "maps void to void return type" do
    parse_rbs <<-RBS
class Foo
  def run: () -> void
end
    RBS
    expect(Registry.at('Foo#run').tag(:return).types).to eq ['void']
  end

  it "maps bool to Boolean" do
    parse_rbs <<-RBS
class Foo
  def valid?: () -> bool
end
    RBS
    expect(Registry.at('Foo#valid?').tag(:return).types).to eq ['Boolean']
  end

  it "maps untyped to Object" do
    parse_rbs <<-RBS
class Foo
  def value: () -> untyped
end
    RBS
    expect(Registry.at('Foo#value').tag(:return).types).to eq ['Object']
  end

  it "handles nullable return type (Type?)" do
    parse_rbs <<-RBS
class Foo
  def find: () -> String?
end
    RBS
    expect(Registry.at('Foo#find').tag(:return).types).to eq ['String', 'nil']
  end

  it "handles union return types" do
    parse_rbs <<-RBS
class Foo
  def id: () -> (String | Integer)
end
    RBS
    ret_types = Registry.at('Foo#id').tag(:return).types
    expect(ret_types).to include('String', 'Integer')
  end

  it "adds @param tags for positional parameters" do
    parse_rbs <<-RBS
class Foo
  def add: (Integer a, Integer b) -> Integer
end
    RBS
    obj = Registry.at('Foo#add')
    param_names = obj.tags(:param).map(&:name)
    expect(param_names).to include('a', 'b')
  end

  it "adds @param with correct types" do
    parse_rbs <<-RBS
class Foo
  def greet: (String name) -> void
end
    RBS
    param = Registry.at('Foo#greet').tags(:param).first
    expect(param.name).to eq 'name'
    expect(param.types).to eq ['String']
  end

  it "adds @overload tags for multiple signatures" do
    parse_rbs <<-RBS
class Foo
  def fetch: (Integer index) -> String
           | (String key) -> String
end
    RBS
    obj = Registry.at('Foo#fetch')
    expect(obj.tags(:overload).length).to eq 2
  end

  it "handles a signature spanning several lines" do
    parse_rbs <<-RBS
class Foo
  def greet: (
    String name, # the name
    Size: Integer
  ) -> String
  def wave: (String name)
          -> String
  def nod:
    (String name) -> String
end
    RBS
    %w(Foo#greet Foo#wave Foo#nod).each do |path|
      obj = Registry.at(path)
      expect(obj.tags(:param).first.name).to eq 'name'
      expect(obj.tags(:param).first.types).to eq ['String']
      expect(obj.tag(:return).types).to eq ['String']
    end
    expect(Registry.at('Foo::Size')).to be_nil
  end

  it "handles an overload spanning several lines" do
    parse_rbs <<-RBS
class Foo
  def fetch: (Integer index) -> String
           | (
               String key
             ) -> Symbol
end
    RBS
    overloads = Registry.at('Foo#fetch').tags(:overload)
    expect(overloads.length).to eq 2
    expect(overloads.last.tag(:return).types).to eq ['Symbol']
  end

  it "handles keyword parameters" do
    parse_rbs <<-RBS
class Foo
  def connect: (host: String, port: Integer) -> void
end
    RBS
    obj = Registry.at('Foo#connect')
    param_names = obj.tags(:param).map(&:name)
    expect(param_names).to include('host:', 'port:')
  end

  it "handles keyword parameters without space after colon" do
    parse_rbs <<-RBS
class Foo
  def connect: (host:String, port:Integer) -> void
end
    RBS
    obj = Registry.at('Foo#connect')
    param_names = obj.tags(:param).map(&:name)
    expect(param_names).to include('host:', 'port:')
  end

  it "ignores inline comments on method declarations" do
    parse_rbs <<-RBS
class Foo
  def name: () -> String # the name
end
    RBS
    expect(Registry.at('Foo#name').tag(:return).types).to eq ['String']
  end

  it "adds @yield and @yieldparam for block parameters" do
    parse_rbs <<-RBS
class Foo
  def each: () { (String item) -> void } -> void
end
    RBS
    obj = Registry.at('Foo#each')
    expect(obj).to have_tag(:yield)
    expect(obj.tags(:yieldparam).first.types).to eq ['String']
  end

  it "preserves docstring comments" do
    parse_rbs <<-RBS
class Foo
  # Returns a greeting string.
  def greet: () -> String
end
    RBS
    expect(Registry.at('Foo#greet').docstring).to eq 'Returns a greeting string.'
  end

  it "sets initialize return type to class name" do
    parse_rbs <<-RBS
class Foo
  def initialize: () -> void
end
    RBS
    obj = Registry.at('Foo#initialize')
    expect(obj.tag(:return).types).to eq ['Foo']
  end

  it "does not override existing @return tag from docstring" do
    parse_rbs <<-RBS
class Foo
  # @return [Bar] always Bar
  def make: () -> Foo
end
    RBS
    obj = Registry.at('Foo#make')
    expect(obj.tag(:return).types).to eq ['Bar']
  end

  it "does not raise on malformed signature with unclosed parenthesis" do
    expect do
      parse_rbs <<-RBS
class Foo
  def broken: (String name -> void
end
      RBS
    end.not_to raise_error
  end

  it "does not raise on malformed block type with unclosed brace" do
    expect do
      parse_rbs <<-RBS
class Foo
  def broken: () { (String -> void } -> void
end
      RBS
    end.not_to raise_error
  end

  describe ".rbs_type_to_yard_types" do
    subject { YARD::Handlers::RBS::MethodHandler }

    it "converts void" do
      expect(subject.rbs_type_to_yard_types('void')).to eq ['void']
    end

    it "converts bool" do
      expect(subject.rbs_type_to_yard_types('bool')).to eq ['Boolean']
    end

    it "converts untyped" do
      expect(subject.rbs_type_to_yard_types('untyped')).to eq ['Object']
    end

    it "converts nil" do
      expect(subject.rbs_type_to_yard_types('nil')).to eq ['nil']
    end

    it "converts Type?" do
      expect(subject.rbs_type_to_yard_types('String?')).to eq ['String', 'nil']
    end

    it "converts union types" do
      expect(subject.rbs_type_to_yard_types('String | Integer')).to eq ['String', 'Integer']
    end

    it "handles nested generics in union" do
      expect(subject.rbs_type_to_yard_types('Array[String] | Hash[Symbol, Integer]')).to \
        eq ['Array[String]', 'Hash[Symbol, Integer]']
    end
  end
end
