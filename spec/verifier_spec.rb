require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Verifier do
  describe '#parse_expressions' do
    it "should create #__execute method" do
      v = Verifier.new("expr1")
      expect(v).to respond_to(:__execute)
    end

    it "should parse @tagname into tag('tagname')" do
      obj = mock(:object)
      expect(obj).to receive(:tag).with('return')
      Verifier.new('@return').call(obj)
    end

    it "should parse @@tagname into object.tags('tagname')" do
      obj = mock(:object)
      expect(obj).to receive(:tags).with('return')
      Verifier.new('@@return').call(obj)
    end

    it "should allow namespaced tag using @{} syntax" do
      obj = mock(:object)
      expect(obj).to receive(:tag).with('yard.return')
      Verifier.new('@{yard.return}').call(obj)
    end

    it "should allow namespaced tags using @{} syntax" do
      obj = mock(:object)
      expect(obj).to receive(:tags).with('yard.return')
      Verifier.new('@@{yard.return}').call(obj)
    end

    it "should call methods on tag object" do
      obj = mock(:object)
      obj2 = mock(:tag)
      expect(obj).to receive(:tag).with('return').and_return obj2
      expect(obj2).to receive(:foo)
      Verifier.new('@return.foo').call(obj)
    end

    it "should send any missing methods to object" do
      obj = mock(:object)
      expect(obj).to receive(:has_tag?).with('return')
      Verifier.new('has_tag?("return")').call(obj)
    end

    it "should allow multiple expressions" do
      obj = mock(:object)
      expect(obj).to receive(:tag).with('return').and_return(true)
      expect(obj).to receive(:tag).with('param').and_return(false)
      expect(Verifier.new('@return', '@param').call(obj)).to eq false
    end
  end

  describe '#o' do
    it "should alias object to o" do
      obj = mock(:object)
      expect(obj).to receive(:a).ordered
      Verifier.new('o.a').call(obj)
    end
  end

  describe '#call' do
    it "should mock a nonexistent tag so that exceptions are not raised" do
      obj = mock(:object)
      expect(obj).to receive(:tag).and_return(nil)
      expect(Verifier.new('@return.text').call(obj)).to eq false
    end

    it "should not fail if no expressions were added" do
      expect{ Verifier.new.call(nil) }.to_not raise_error
    end

    it "should always ignore proxy objects and return true" do
      v = Verifier.new('tag(:x)')
      expect{ expect(v.call(P('foo'))).to be true }.to_not raise_error
    end
  end

  describe '#expressions' do
    it "should maintain a list of all unparsed expressions" do
      expect(Verifier.new('@return.text', '@private').expressions).to eq ['@return.text', '@private']
    end
  end

  describe '#expressions=' do
    it "should recompile expressions when attribute is modified" do
      obj = mock(:object)
      expect(obj).to receive(:tag).with('return')
      v = Verifier.new
      v.expressions = ['@return']
      v.call(obj)
    end
  end

  describe '#add_expressions' do
    it "should add new expressions and recompile" do
      obj = mock(:object)
      expect(obj).to receive(:tag).with('return')
      v = Verifier.new
      v.add_expressions '@return'
      v.call(obj)
    end
  end
end
