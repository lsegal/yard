require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe SymbolHash do

  it "should allow access to keys as String or Symbol" do
    h = SymbolHash.new(false)
    h['test'] = true
    expect(h[:test]).to eq true
    expect(h['test']).to eq true
  end

  it "should #delete by key as String or Symbol" do
    h = SymbolHash.new
    expect(h.keys.length).to eq 0

    h['test'] = true
    expect(h.keys.length).to eq 1

    h.delete(:test)
    expect(h.keys.length).to eq 0

    h[:test] = true
    expect(h.keys.length).to eq 1

    h.delete('test')
    expect(h.keys.length).to eq 0
  end

  it "should return same #has_key? for key as String or Symbol" do
    h = SymbolHash.new
    h[:test] = 1
    expect(h.has_key?(:test)).to eq true
    expect(h.has_key?('test')).to eq true
  end

  it "should symbolize value if it is a String (and only a string)" do
    class Substring < String; end

    h = SymbolHash.new
    h['test1'] = "hello"
    h['test2'] = Substring.new("hello")
    expect(h['test1']).to eq :hello
    expect(h['test2']).to eq "hello"
  end

  it "should not symbolize value if SymbolHash.new(false) is created" do
    h = SymbolHash.new(false)
    h['test'] = "hello"
    expect(h[:test]).to eq "hello"
  end

  it "should not symbolize value if it is not a String" do
    h = SymbolHash.new
    h['test'] = [1,2,3]
    expect(h['test']).to eq [1,2,3]
  end

  it "should support symbolization using #update or #merge!" do
    h = SymbolHash.new
    h.update('test' => 'value')
    expect(h[:test]).to eq :value
    h.merge!('test' => 'value2')
    expect(h[:test]).to eq :value2
  end

  it "should support symbolization non-destructively using #merge" do
    h = SymbolHash.new
    expect(h.merge('test' => 'value')[:test]).to eq :value
    expect(h).to eq SymbolHash.new
  end

  it "should support #initializing of a hash" do
    h = SymbolHash[:test => 1]
    expect(h[:test]).to eq 1
    expect(h[:somethingelse]).to be_nil
  end

  it "should support reverse merge syntax" do
    opts = {}
    opts = SymbolHash[
      'default' => 1
    ].update(opts)
    expect(opts.keys).to eq [:default]
    expect(opts[:default]).to eq 1
  end
end
