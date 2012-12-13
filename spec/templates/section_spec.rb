require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Templates::Section do
  include YARD::Templates

  describe '#initialize' do
    it "should convert first argument to splat if it is array" do
      s = Section.new(:name, [:foo, :bar])
      expect(s.name).to eq :name
      expect(s[0].name).to eq :foo
      expect(s[1].name).to eq :bar
    end

    it "should allow initialization with Section objects" do
      s = Section.new(:name, [:foo, Section.new(:bar)])
      expect(s.name).to eq :name
      expect(s[0]).to eq Section.new(:foo)
      expect(s[1]).to eq Section.new(:bar)
    end

    it "should make a list of sections" do
      s = Section.new(:name, [:foo, [:bar]])
      expect(s).to eq Section.new(:name, Section.new(:foo, Section.new(:bar)))
    end
  end

  describe '#[]' do
    it "should use Array#[] if argument is integer" do
      expect(Section.new(:name, [:foo, :bar])[0].name).to eq :foo
    end

    it "should return new Section object if more than one argument" do
      expect(Section.new(:name, :foo, :bar, :baz)[1, 2]).to eq Section.new(:name, :bar, :baz)
    end

    it "should return new Section object if arg is Range" do
      expect(Section.new(:name, :foo, :bar, :baz)[1..2]).to eq Section.new(:name, :bar, :baz)
    end

    it "should look for section by name if arg is object" do
      expect(Section.new(:name, :foo, :bar, [:baz])[:bar][:baz]).to eq Section.new(:baz)
    end
  end

  describe '#eql?' do
    it "should check for equality of two equal sections" do
      Section.new(:foo, [:a, :b]).should be_eql(Section.new(:foo, :a, :b))
      expect(Section.new(:foo, [:a, :b])).to eq Section.new(:foo, :a, :b)
    end

    it "should not be equal if section names are different" do
      Section.new(:foo, [:a, :b]).should_not be_eql(Section.new(:bar, :a, :b))
      Section.new(:foo, [:a, :b]).should_not == Section.new(:bar, :a, :b)
    end
  end

  describe '#==' do
    it "should allow comparison to Symbol" do
      expect(Section.new(:foo, 2, 3)).to eq :foo
    end

    it "should allow comparison to String" do
      expect(Section.new("foo", 2, 3)).to eq "foo"
    end

    it "should allow comparison to Template" do
      t = YARD::Templates::Engine.template!(:xyzzy, '/full/path/xyzzy')
      expect(Section.new(t, 2, 3)).to eq t
    end

    it "should allow comparison to Section" do
      expect(Section.new(1, [2, 3])).to eq Section.new(1, 2, 3)
    end

    it "should allow comparison to Object" do
      expect(Section.new(1, [2, 3])).to eq 1
    end

    it "should allow comparison to Array" do
      expect(Section.new(1, 2, [3])).to eq [1, [2, [3]]]
    end
  end

  describe '#to_a' do
    it "should convert Section to regular Array list" do
      arr = Section.new(1, 2, [3, [4]]).to_a
      expect(arr.class).to eq Array
      expect(arr).to eq [1, [2, [3, [4]]]]
    end
  end

  describe '#place' do
    it "should place objects as Sections" do
      expect(Section.new(1, 2, 3).place(4).before(3)).to eq [1, [2, 4, 3]]
    end

    it "should place objects anywhere inside Section with before/after_any" do
      expect(Section.new(1, 2, [3, [4]]).place(5).after_any(4)).to eq [1, [2, [3, [4, 5]]]]
      expect(Section.new(1, 2, [3, [4]]).place(5).before_any(4)).to eq [1, [2, [3, [5, 4]]]]
    end

    it "should allow multiple sections to be placed" do
      expect(Section.new(1, 2, 3).place(4, 5).after(3).to_a).to eq [1, [2, 3, 4, 5]]
      expect(Section.new(1, 2, 3).place(4, [5]).after(3).to_a).to eq [1, [2, 3, 4, [5]]]
    end
  end

  describe '#push' do
    it "should push objects as Sections" do
      s = Section.new(:foo)
      s.push :bar
      expect(s[0]).to eq Section.new(:bar)
    end

    it "should alias to #<<" do
      s = Section.new(1)
      s << :index
      s[:index].should be_a(Section)
    end
  end

  describe '#unshift' do
    it "should unshift objects as Sections" do
      s = Section.new(:foo)
      s.unshift :bar
      expect(s[0]).to eq Section.new(:bar)
    end
  end

  describe '#any' do
    it "should find item inside sections" do
      s = Section.new(:foo, Section.new(:bar, Section.new(:bar)))
      s.any(:bar).push(:baz)
      expect(s.to_a).to eq [:foo, [:bar, [:bar, :baz]]]
    end

    it "should find item in any deeply nested set of sections" do
      s = Section.new(:foo, Section.new(:bar, Section.new(:baz)))
      s.any(:baz).push(:qux)
      expect(s.to_a).to eq [:foo, [:bar, [:baz, [:qux]]]]
    end
  end
end
