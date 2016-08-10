require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Verifier do
  describe "#parse_expressions" do
    it "parses @tagname into tag('tagname')" do
      obj = double(:object)
      expect(obj).to receive(:tag).with('return')
      Verifier.new('@return').call(obj)
    end

    it "parses @@tagname into object.tags('tagname')" do
      obj = double(:object)
      expect(obj).to receive(:tags).with('return')
      Verifier.new('@@return').call(obj)
    end

    it "allows namespaced tag using @{} syntax" do
      obj = double(:object)
      expect(obj).to receive(:tag).with('yard.return')
      Verifier.new('@{yard.return}').call(obj)
    end

    it "allows namespaced tags using @{} syntax" do
      obj = double(:object)
      expect(obj).to receive(:tags).with('yard.return')
      Verifier.new('@@{yard.return}').call(obj)
    end

    it "calls methods on tag object" do
      obj = double(:object)
      obj2 = double(:tag)
      expect(obj).to receive(:tag).with('return').and_return obj2
      expect(obj2).to receive(:foo)
      Verifier.new('@return.foo').call(obj)
    end

    it "sends any missing methods to object" do
      obj = double(:object)
      expect(obj).to receive(:has_tag?).with('return')
      Verifier.new('has_tag?("return")').call(obj)
    end

    it "allows multiple expressions" do
      obj = double(:object)
      expect(obj).to receive(:tag).with('return').and_return(true)
      expect(obj).to receive(:tag).with('param').and_return(false)
      expect(Verifier.new('@return', '@param').call(obj)).to be false
    end

    it "will not parse constants or blocks" do
      expect(lambda { Verifier.new('File.unlink("x")') }).to raise_error(SyntaxError, /disallowed const/)
      expect(lambda { Verifier.new('[].each { }') }).to raise_error(SyntaxError, /disallowed lbrace/)
      expect(lambda { Verifier.new('o.send :puts, "test"') }).to raise_error(SyntaxError, /disallowed #send/)
      expect(lambda { Verifier.new('o.__send__ :puts, "test"') }).to raise_error(SyntaxError, /disallowed #send/)
      expect(lambda { Verifier.new('o.require "foo"') }).to raise_error(SyntaxError, /disallowed #require/)
      expect(lambda { Verifier.new('require "foo"') }).to raise_error(SyntaxError, /disallowed #require/)
    end

    it "does not allow calls outside of object" do
      obj = CodeObjects::ClassObject.new(nil, "A")
      expect(lambda { Verifier.new('raise "test"').call(obj) }).to raise_error(NoMethodError)
      expect(lambda { Verifier.new('o.puts "test"').call(obj) }).to raise_error(NoMethodError)
    end
  end

  describe "#o" do
    it "aliases object to o" do
      obj = double(:object)
      expect(obj).to receive(:a).ordered
      Verifier.new('o.a').call(obj)
    end
  end

  describe "#call" do
    it "doubles a nonexistent tag so that exceptions are not raised" do
      obj = double(:object)
      expect(obj).to receive(:tag).and_return(nil)
      expect(Verifier.new('@return.text').call(obj)).to be false
    end

    it "does not fail if no expressions were added" do
      expect { Verifier.new.call(nil) }.not_to raise_error
    end

    it "always ignores proxy objects and return true" do
      v = Verifier.new('tag(:x)')
      expect { expect(v.call(P('foo'))).to be true }.not_to raise_error
    end
  end

  describe "#expressions" do
    it "maintains a list of all unparsed expressions" do
      expect(Verifier.new('@return.text', '@private').expressions).to eq ['@return.text', '@private']
    end
  end

  describe "#expressions=" do
    it "recompiles expressions when attribute is modified" do
      obj = double(:object)
      expect(obj).to receive(:tag).with('return')
      v = Verifier.new
      v.expressions = ['@return']
      v.call(obj)
    end
  end

  describe "#add_expressions" do
    it "adds new expressions and recompile" do
      obj = double(:object)
      expect(obj).to receive(:tag).with('return')
      v = Verifier.new
      v.add_expressions '@return'
      v.call(obj)
    end
  end
end