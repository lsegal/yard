# frozen_string_literal: true

RSpec.describe YARD::Tags::TypesExplainer do
  def type(name)
    YARD::Tags::TypesExplainer::Type.new(name)
  end

  describe "LITERALMATCH" do
    it "matches symbol literals" do
      expect(":symbol"[described_class::LITERALMATCH]).to eq ":symbol"
      expect(":some_symbol"[described_class::LITERALMATCH]).to eq ":some_symbol"
      expect("not_a_symbol"[described_class::LITERALMATCH]).to be nil
    end

    it "matches single-quoted string literals" do
      expect("'string'"[described_class::LITERALMATCH]).to eq "'string'"
      expect("'some string with spaces'"[described_class::LITERALMATCH]).to eq "'some string with spaces'"
      expect("not_quoted"[described_class::LITERALMATCH]).to be nil
    end

    it "matches double-quoted string literals" do
      expect('"string"'[described_class::LITERALMATCH]).to eq '"string"'
      expect('"some string with spaces"'[described_class::LITERALMATCH]).to eq '"some string with spaces"'
      expect("not_quoted"[described_class::LITERALMATCH]).to be nil
    end
  end

  describe YARD::Tags::TypesExplainer::Type, '#to_s' do
    before { @t = described_class.new(nil) }

    it "works for a class/module reference" do
      @t.name = "ClassModuleName"
      expect(@t.to_s).to eq "a ClassModuleName"
      expect(@t.to_s(false)).to eq "ClassModuleNames"

      @t.name = "XYZ"
      expect(@t.to_s).to eq "a XYZ"
      expect(@t.to_s(false)).to eq "XYZ's"

      @t.name = "Array"
      expect(@t.to_s).to eq "an Array"
      expect(@t.to_s(false)).to eq "Arrays"
    end
    
    it "works for a constant value" do
      ['false', 'true', 'nil', '4'].each do |name|
        @t.name = name
        expect(@t.to_s).to eq name
        expect(@t.to_s(false)).to eq name
      end
    end
  end

  describe YARD::Tags::TypesExplainer::DuckType, '#to_s' do
    it "works for a method (ducktype)" do
      duck_type = described_class.new("#mymethod")
      expect(duck_type.to_s).to eq "an object that responds to #mymethod"
      expect(duck_type.to_s(false)).to eq "objects that respond to #mymethod"
    end

    it "works for multiple methods joined with '&' (ducktype)" do
      duck_type = described_class.new("#mymethod&#myothermethod&#mythirdmethod")
      duck_type.name = "#mymethod&#myothermethod&#mythirdmethod"
      expect(duck_type.to_s).to eq "an object that responds to #mymethod, #myothermethod and #mythirdmethod"
      expect(duck_type.to_s(false)).to eq "objects that respond to #mymethod, #myothermethod and #mythirdmethod"
    end

    it "works for multiple methods joined with ' & ' (ducktype)" do
      duck_type = described_class.new("#mymethod & #myothermethod & #mythirdmethod")
      expect(duck_type.to_s).to eq "an object that responds to #mymethod, #myothermethod and #mythirdmethod"
      expect(duck_type.to_s(false)).to eq "objects that respond to #mymethod, #myothermethod and #mythirdmethod"
    end
  end

  describe YARD::Tags::TypesExplainer::IntersectionType, '#to_s' do
    it "works for two types" do
      intersection = described_class.new([type("Foo"), type("Bar")])
      expect(intersection.to_s).to eq "both a Foo and a Bar"
      expect(intersection.to_s(false)).to eq "both Foos and Bars"
    end

    it "works for more than two types" do
      intersection = described_class.new([type("Foo"), type("Bar"), type("Baz")])
      expect(intersection.to_s).to eq "all of a Foo, a Bar and a Baz"
    end
  end

  describe YARD::Tags::TypesExplainer::GroupType, '#to_s' do
    it "works for two types" do
      group = described_class.new([type("Foo"), type("Bar")])
      expect(group.to_s).to eq "(a Foo or a Bar)"
      expect(group.to_s(false)).to eq "(Foos or Bars)"
    end

    it "works for more than two types" do
      group = described_class.new([type("Foo"), type("Bar"), type("Baz")])
      expect(group.to_s).to eq "(a Foo, a Bar or a Baz)"
    end

    it "adds defensive parens around an IntersectionType member" do
      intersection = YARD::Tags::TypesExplainer::IntersectionType.new([type("Foo"), type("Bar")])
      group = described_class.new([intersection, type("Baz")])
      expect(group.to_s).to eq "((both a Foo and a Bar) or a Baz)"
    end

    it "adds defensive parens around a multi-method DuckType member" do
      duck = YARD::Tags::TypesExplainer::DuckType.new("#foo & #bar")
      group = described_class.new([duck, type("Baz")])
      expect(group.to_s).to eq "((an object that responds to #foo and #bar) or a Baz)"
    end

    it "does not add extra parens around a single-method DuckType member" do
      duck = YARD::Tags::TypesExplainer::DuckType.new("#foo")
      group = described_class.new([duck, type("Baz")])
      expect(group.to_s).to eq "(an object that responds to #foo or a Baz)"
    end
  end

  describe YARD::Tags::TypesExplainer::LiteralType, '#to_s' do
    it "works for literal values" do
      [':symbol', "'5'"].each do |name|
        literal_type = described_class.new(name)
        expect(literal_type.to_s).to eq "a literal value #{name}"
        expect(literal_type.to_s(false)).to eq "a literal value #{name}"
      end
    end
  end

  describe YARD::Tags::TypesExplainer::CollectionType, '#to_s' do
    before { @t = described_class.new("Array", nil) }

    it "can contain one item" do
      @t.types = [type("Object")]
      expect(@t.to_s).to eq "an Array of (Objects)"
    end

    it "can contain more than one item" do
      @t.types = [type("Object"), type("String"), type("Symbol")]
      expect(@t.to_s).to eq "an Array of (Objects, Strings or Symbols)"
    end

    it "can contain nested collections" do
      @t.types = [described_class.new("List", [type("Object")])]
      expect(@t.to_s).to eq "an Array of (a List of (Objects))"
    end

    it "flattens a GroupType member into its own union list" do
      group = YARD::Tags::TypesExplainer::GroupType.new([type("Foo"), type("Bar")])
      @t.types = [group, type("Baz")]
      expect(@t.to_s).to eq "an Array of (Foos, Bars or Bazs)"
    end

    it "lists a non-allow-listed name's 2+ type parameters without pluralizing or asserting union/order" do
      result = described_class.new("Result", [type("Success"), type("Failure")])
      expect(result.to_s).to eq "a Result with type parameters (a Success, a Failure)"
    end
  end

  describe YARD::Tags::TypesExplainer::FixedCollectionType, '#to_s' do
    before { @t = described_class.new("Array", nil) }

    it "can contain one item" do
      @t.types = [type("Object")]
      expect(@t.to_s).to eq "an Array containing (an Object)"
    end

    it "can contain more than one item" do
      @t.types = [type("Object"), type("String"), type("Symbol")]
      expect(@t.to_s).to eq "an Array containing (an Object followed by a String followed by a Symbol)"
    end

    it "can contain nested collections" do
      @t.types = [described_class.new("List", [type("Object")])]
      expect(@t.to_s).to eq "an Array containing (a List containing (an Object))"
    end
  end

  describe YARD::Tags::TypesExplainer::HashCollectionType, '#to_s' do
    before { @t = described_class.new("Hash", nil, nil) }

    it "can contain a single key type and value type" do
      @t.key_types = [type("Object")]
      @t.value_types = [type("Object")]
      expect(@t.to_s).to eq "a Hash with keys made of (Objects) and values of (Objects)"
    end

    it "can contain multiple key types" do
      @t.key_types = [type("Key"), type("String")]
      @t.value_types = [type("Object")]
      expect(@t.to_s).to eq "a Hash with keys made of (Keys or Strings) and values of (Objects)"
    end

    it "can contain multiple value types" do
      @t.key_types = [type("String")]
      @t.value_types = [type("true"), type("false")]
      expect(@t.to_s).to eq "a Hash with keys made of (Strings) and values of (true or false)"
    end
  end

  describe YARD::Tags::TypesExplainer::Parser, '#parse' do
    def parse(types)
      described_class.new(types).parse
    end

    def parse_fail(types)
      expect { parse(types) }.to raise_error(SyntaxError)
    end

    it "parses a regular class name" do
      type = parse("MyClass")
      expect(type.size).to eq 1
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::Type)
      expect(type.first.name).to eq "MyClass"
    end

    it "parses a path reference name" do
      type = parse("A::B")
      expect(type.size).to eq 1
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::Type)
      expect(type.first.name).to eq "A::B"
    end

    it "parses a list of simple names" do
      type = parse("A, B::C, D, E")
      expect(type.size).to eq 4
      expect(type[0].name).to eq "A"
      expect(type[1].name).to eq "B::C"
      expect(type[2].name).to eq "D"
      expect(type[3].name).to eq "E"
    end

    it 'parses a list of literal values' do
      type = parse("true, false, nil, 4, :symbol, '5'")
      expect(type.size).to eq 6
      expect(type[0].name).to eq "true"
      expect(type[1].name).to eq "false"
      expect(type[2].name).to eq "nil"
      expect(type[3].name).to eq "4"
      expect(type[4].name).to eq ":symbol"
      expect(type[5].name).to eq "'5'"
    end

    it "parses a collection type" do
      type = parse("MyList<String>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.types.size).to eq 1
      expect(type.first.name).to eq "MyList"
      expect(type.first.types.first.name).to eq "String"
    end

    it "keeps the implicit-union CollectionType for a single type parameter, regardless of name" do
      type = parse("MyBox<Contents>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
    end

    it "keeps the implicit-union CollectionType for allow-listed names with 2+ parameters" do
      type = parse("Array<Foo, Bar>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      type = parse("Set<Foo, Bar>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
    end

    it "renders a non-allow-listed name's 2+ parameters neutrally" do
      type = parse("Result<Success, Failure>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.name).to eq "Result"
      expect(type.first.types.map(&:name)).to eq ["Success", "Failure"]
      expect(type.first.to_s).to eq "a Result with type parameters (a Success, a Failure)"
    end

    it "special-cases Hash<KeyType, ValueType> to match Hash{K=>V}'s key/value rendering" do
      by_angle_brackets = parse("Hash<KeyType, ValueType>")
      by_braces = parse("Hash{KeyType => ValueType}")
      expect(by_angle_brackets.first).to be_a(YARD::Tags::TypesExplainer::HashCollectionType)
      expect(by_angle_brackets.first.key_types.map(&:name)).to eq by_braces.first.key_types.map(&:name)
      expect(by_angle_brackets.first.value_types.map(&:name)).to eq by_braces.first.value_types.map(&:name)
    end

    it "falls back to a neutral CollectionType for Hash<...> with the wrong number of parameters" do
      type = parse("Hash<A, B, C>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.to_s).to eq "a Hash with type parameters (an A, a B, a C)"
      type = parse("Hash<A>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.to_s).to eq "a Hash of (A's)"
    end

    it "groups '|' within a single slot of a non-allow-listed <...>, since its slots are positional" do
      type = parse("Result<Success | Failure, Other>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.types.size).to eq 2
      expect(type.first.types.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(type.first.types.first.types.map(&:name)).to eq ["Success", "Failure"]
      expect(type.first.types.last.name).to eq "Other"
    end

    it "groups '|' within a slot of Hash<KeyType, ValueType>, since its slots are positional" do
      type = parse("Hash<KeyType | OtherKeyType, ValueType>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::HashCollectionType)
      expect(type.first.key_types.size).to eq 1
      expect(type.first.key_types.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(type.first.key_types.first.types.map(&:name)).to eq ["KeyType", "OtherKeyType"]
    end

    it "parses '|' within a slot of an allow-listed <...>, mixed with ','" do
      type = parse("Array<Foo | Bar, Baz>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.types.size).to eq 2
      expect(type.first.types.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(type.first.types.first.types.map(&:name)).to eq ["Foo", "Bar"]
      expect(type.first.types.last.name).to eq "Baz"
    end

    it "still renders '|' as a flat alternative inside allow-listed <...>, where the whole list is a union" do
      by_comma = YARD::Tags::TypesExplainer.explain("Array<Foo, Bar>")
      by_pipe = YARD::Tags::TypesExplainer.explain("Array<Foo | Bar>")
      expect(by_pipe).to eq by_comma
    end

    it "allows a collection type without a name" do
      type = parse("<String>")
      expect(type.first.name).to eq "Array"
    end

    it "allows a fixed collection type without a name" do
      type = parse("(String)")
      expect(type.first.name).to eq "Array"
    end

    it "parses a grouped union inside square brackets as a GroupType" do
      type = parse("[String | Symbol]")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(type.first.types.map(&:name)).to eq ["String", "Symbol"]
    end

    it "treats ',' and '|' as synonyms inside square brackets" do
      by_comma = parse("[String, Symbol]")
      by_pipe = parse("[String | Symbol]")
      expect(by_comma.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(by_comma.first.types.map(&:name)).to eq by_pipe.first.types.map(&:name)
    end

    it "treats '|' as a synonym for ',' at the top level" do
      by_comma = parse("String, Symbol")
      by_pipe = parse("String | Symbol")
      expect(by_pipe.map(&:name)).to eq by_comma.map(&:name)
    end

    it "treats '|' as a synonym for ',' inside a collection type" do
      type = parse("Array<String | Symbol>")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::CollectionType)
      expect(type.first.to_s).to eq "an Array of (Strings or Symbols)"
    end

    it "allows a grouped union as a fixed-tuple slot via square brackets" do
      type = parse("Array([String | Symbol], Integer)")
      expect(type.first).to be_a(YARD::Tags::TypesExplainer::FixedCollectionType)
      expect(type.first.types.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(type.first.types.first.types.map(&:name)).to eq ["String", "Symbol"]
      expect(type.first.types.last.name).to eq "Integer"
    end

    it "allows a grouped union as a fixed-tuple slot via a bare '|', equivalent to square brackets" do
      bare = parse("Array(String | Symbol, Integer)")
      bracketed = parse("Array([String | Symbol], Integer)")
      expect(bare.first).to be_a(YARD::Tags::TypesExplainer::FixedCollectionType)
      expect(bare.first.types.first).to be_a(YARD::Tags::TypesExplainer::GroupType)
      expect(bare.first.types.first.types.map(&:name)).to eq ["String", "Symbol"]
      expect(bare.first.types.last.name).to eq "Integer"
      expect(bare.first.types.first.types.map(&:name)).to eq bracketed.first.types.first.types.map(&:name)
    end

    it "does not allow a dangling '|' inside a fixed-tuple slot" do
      parse_fail "Array(String |, Integer)"
      parse_fail "Array(| String, Integer)"
    end

    it "does not allow '[' to follow a type name" do
      parse_fail "Foo[String]"
    end

    it "allows a hash collection type without a name" do
      type = parse("{K=>V}")
      expect(type.first.name).to eq "Hash"
    end

    it "parses types after a hash collection as top-level types" do
      types = parse("Hash{Symbol => String}, nil")

      expect(types.size).to eq 2
      expect(types.first).to be_a(YARD::Tags::TypesExplainer::HashCollectionType)
      expect(types.first.key_types.map(&:name)).to eq ["Symbol"]
      expect(types.first.value_types.map(&:name)).to eq ["String"]
      expect(types.last.name).to eq "nil"
    end

    it "parses constant values" do
      type = parse("false, true, nil, 4, :foo")
      expect(type.map(&:name)).to eq ['false', 'true', 'nil', '4', ':foo']
    end

    it "combines '&'-joined hash keys into an IntersectionType" do
      type = parse("Hash{Foo & Bar => String}")
      expect(type.first.key_types.size).to eq 1
      expect(type.first.key_types.first).to be_a(YARD::Tags::TypesExplainer::IntersectionType)
      expect(type.first.key_types.first.types.map(&:name)).to eq ["Foo", "Bar"]
    end

    it "treats ',' and '|' as synonyms for hash keys" do
      by_comma = parse("Hash{Foo, Bar => String}")
      by_pipe = parse("Hash{Foo | Bar => String}")
      expect(by_comma.first.key_types.map(&:name)).to eq by_pipe.first.key_types.map(&:name)
    end

    it "does not silently accept two hash keys with no separator between them" do
      parse_fail "Hash{Foo Bar => String}"
    end

    it "does not accept two commas in a row" do
      parse_fail "A,,B"
    end

    it "does not accept two types not separated by a comma" do
      parse_fail "A B"
    end

    it "does not allow a comma without a following type" do
      parse_fail "A, "
    end

    it "fails on any unrecognized character" do
      parse_fail "$"
    end
  end

  describe ".explain" do
    it "parses an arbitrarily nested collection type" do
      explain = YARD::Tags::TypesExplainer.explain("Array<String, Array<Symbol, List(String, {K=>V})>>")
      result = "an Array of (Strings or an Array of (Symbols or a List containing
        (a String followed by a Hash with keys made of (K's) and values of (V's))))"
      expect(explain).to eq result.delete("\n").squeeze(' ')
    end

    it "parses various examples" do
      expect = {
        "Fixnum, Foo, Object, true" => "a Fixnum; a Foo; an Object; true",
        "#read" => "an object that responds to #read",
        "Array<String, Symbol, #read>" => "an Array of (Strings, Symbols or objects that respond to #read)",
        "Set<Number>" => "a Set of (Numbers)",
        "Array(String, Symbol)" => "an Array containing (a String followed by a Symbol)",
        "Hash{String => Symbol, Number}" => "a Hash with keys made of (Strings) and values of (Symbols or Numbers)",
        "Array<Foo, Bar>, List(String, Symbol, #to_s), {Foo, Bar => Symbol, Number}" => "an Array of (Foos or Bars);
          a List containing (a String followed by a Symbol followed by an object that responds to #to_s);
          a Hash with keys made of (Foos or Bars) and values of (Symbols or Numbers)",
        "#weird_method?, #<=>, #!=" => "an object that responds to #weird_method?;
          an object that responds to #<=>;
          an object that responds to #!=",
        ":symbol, 'string'" => "a literal value :symbol; a literal value 'string'",
        "Hash{:key_one, :key_two => String; :key_three => Symbol}" => "a Hash with keys made of (a literal value :key_one or a literal value :key_two) and values of (Strings) and keys made of (a literal value :key_three) and values of (Symbols)",
        "Hash{:key_one, :key_two => String; :key_three => Symbol; :key_four => Hash{:sub_key_one => String}}" => "a Hash with keys made of (a literal value :key_one or a literal value :key_two) and values of (Strings) and keys made of (a literal value :key_three) and values of (Symbols) and keys made of (a literal value :key_four) and values of (a Hash with keys made of (a literal value :sub_key_one) and values of (Strings))",
        "Hash{:key_one => String, Number; :key_two => String}" => "a Hash with keys made of (a literal value :key_one) and values of (Strings or Numbers) and keys made of (a literal value :key_two) and values of (Strings)"
      }
      expect.each do |input, expected|
        explain = YARD::Tags::TypesExplainer.explain(input)
        expect(explain).to eq expected.delete("\n").squeeze(' ')
      end
    end

    it "parses intersection types (`&`)" do
      expect = {
        "Foo & Bar" => "both a Foo and a Bar",
        "Foo & Bar & Baz" => "all of a Foo, a Bar and a Baz",
        "Array<Foo & Bar>" => "an Array of (both Foos and Bars)",
        # `&` binds tighter than `,`, matching RBS's `A & B | C` == `(A & B) | C`
        "Foo & Bar, Baz & Qux" => "both a Foo and a Bar; both a Baz and a Qux",
        "Foo, Bar & Baz" => "a Foo; both a Bar and a Baz",
        # consecutive duck-types joined by `&` collapse into a single duck-type,
        # matching the pre-existing "#method_one & #method_two" convention
        "#read & #write" => "an object that responds to #read and #write",
        "#read&#write&#close" => "an object that responds to #read, #write and #close",
        # a duck-type intersected with a real type stays a full intersection
        "Foo & #read" => "both a Foo and an object that responds to #read"
      }
      expect.each do |input, expected|
        explain = YARD::Tags::TypesExplainer.explain(input)
        expect(explain).to eq expected.delete("\n").squeeze(' ')
      end
    end

    it "parses grouped unions (`[A | B]`)" do
      expect = {
        # standalone, redundant with a plain top-level union, but legal
        "[Integer | String]" => "(an Integer or a String)",
        # the motivating case: a union in a fixed-tuple slot, which `,`
        # can't express there since it already means "next slot"
        "Array([Integer | String], Symbol)" =>
          "an Array containing ((an Integer or a String) followed by a Symbol)",
        "Hash{String => [Integer | Symbol]}" =>
          "a Hash with keys made of (Strings) and values of ((Integers or Symbols))"
      }
      expect.each do |input, expected|
        explain = YARD::Tags::TypesExplainer.explain(input)
        expect(explain).to eq expected.delete("\n").squeeze(' ')
      end
    end

    it "composes `&` and `[A | B]` together, with `&` binding tighter than `|`" do
      expect = {
        # a group used as one conjunct of an intersection
        "[Integer | String] & Comparable" => "both (an Integer or a String) and a Comparable",
        "Comparable & [Integer | String]" => "both a Comparable and (an Integer or a String)",
        # `&` binds tighter than `|` *inside* a group too, matching how it
        # already binds tighter than `,` everywhere else: `A & B | C` inside
        # `[...]` groups parses as `(A & B) | C`, not `A & (B | C)`. The
        # `&`-joined conjunct has no punctuation of its own to mark where it
        # ends, so the group adds defensive parens around it (only) to keep
        # the English rendering unambiguous, matching the real parse tree.
        "[Foo & Bar | Baz]" => "((both a Foo and a Bar) or a Baz)",
        "[Foo | Bar & Baz]" => "(a Foo or (both a Bar and a Baz))",
        # duck-types inside a group are NOT collapsed the way `&`-joined ones
        # are - grouping is a real alternative ("either responds to #foo, or
        # responds to #bar"), not the same method-list convention. But a
        # multi-method duck-type (already `&`-collapsed before the `|` is
        # seen) gets the same defensive-parens treatment as `&` above.
        "[#foo | #bar]" => "(an object that responds to #foo or an object that responds to #bar)",
        "[#foo & #bar | #baz]" =>
          "((an object that responds to #foo and #bar) or an object that responds to #baz)",
        # a group nested inside another group's slot - GroupType always
        # parenthesizes itself, so no extra disambiguation is needed here
        "Array([[Integer | String] | Symbol], Number)" =>
          "an Array containing (((an Integer or a String) or a Symbol) followed by a Number)"
      }
      expect.each do |input, expected|
        explain = YARD::Tags::TypesExplainer.explain(input)
        expect(explain).to eq expected.delete("\n").squeeze(' ')
      end
    end

    it "treats '|' as a synonym for ',' everywhere a union is legal" do
      # '&' never needs '[...]' - it's legal (and binds tightest) everywhere
      expect(YARD::Tags::TypesExplainer.explain("Array<Foo & Bar, Baz>")).to eq(
        "an Array of (both Foos and Bars or Bazs)"
      )
      # a bare '|' at the top level is just another spelling of ','
      expect(YARD::Tags::TypesExplainer.explain("Foo & Bar | Baz")).to eq(
        YARD::Tags::TypesExplainer.explain("Foo & Bar, Baz")
      )
      # and ',' is likewise accepted as a synonym for '|' inside '[...]'
      expect(YARD::Tags::TypesExplainer.explain("[Foo & Bar, Baz]")).to eq(
        YARD::Tags::TypesExplainer.explain("[Foo & Bar | Baz]")
      )
    end

    it "lets '|' group a fixed-tuple slot directly, equivalent to wrapping that slot in '[...]'" do
      expect(YARD::Tags::TypesExplainer.explain("Array(Foo | Bar, Baz)")).to eq(
        YARD::Tags::TypesExplainer.explain("Array([Foo | Bar], Baz)")
      )
      expect(YARD::Tags::TypesExplainer.explain("Array(Foo | Bar, Baz)")).to eq(
        "an Array containing ((a Foo or a Bar) followed by a Baz)"
      )
      # '&' still binds tighter than '|' inside a fixed-tuple slot, exactly
      # as it does everywhere else
      expect(YARD::Tags::TypesExplainer.explain("Array(Foo & Bar | Baz, Qux)")).to eq(
        "an Array containing (((both a Foo and a Bar) or a Baz) followed by a Qux)"
      )
      expect(YARD::Tags::TypesExplainer.explain("Array(Foo | Bar & Baz, Qux)")).to eq(
        "an Array containing ((a Foo or (both a Bar and a Baz)) followed by a Qux)"
      )
    end

    it "still needs '[...]' to group a union used as one conjunct of a top-level intersection" do
      # without brackets, '|' at the top level is just ',' - so this is two
      # independent top-level items, NOT one intersection
      expect(YARD::Tags::TypesExplainer.explain("Foo | Bar & Baz")).to eq(
        "a Foo; both a Bar and a Baz"
      )
      # '[...]' raises the union's precedence above '&' to get the other reading
      expect(YARD::Tags::TypesExplainer.explain("[Foo | Bar] & Baz")).to eq(
        "both (a Foo or a Bar) and a Baz"
      )
    end

    it "does not assume <...> always means union, for names that aren't known collections" do
      expect = {
        # allow-listed names keep the implicit-union reading
        "Array<Foo, Bar>" => "an Array of (Foos or Bars)",
        "Set<Foo, Bar>" => "a Set of (Foos or Bars)",
        # Hash<KeyType, ValueType> is documented as positional (key, then
        # value), matching Hash{K=>V} - not "KeyTypes or ValueTypes"
        "Hash<Symbol, String>" => "a Hash with keys made of (Symbols) and values of (Strings)",
        # a single parameter is never ambiguous, so it's unaffected
        # regardless of the name
        "Box<Contents>" => "a Box of (Contentss)",
        # an unrecognized name with 2+ parameters doesn't assert union -
        # RBS-style positional generics like Result<Success, Failure> are
        # exactly the case this protects
        "Result<Success, Failure>" => "a Result with type parameters (a Success, a Failure)"
      }
      expect.each do |input, expected|
        explain = YARD::Tags::TypesExplainer.explain(input)
        expect(explain).to eq expected.delete("\n").squeeze(' ')
      end
    end

    it "groups '|' within a slot of a non-implicit-union '<...>', instead of unioning the whole list" do
      expect(YARD::Tags::TypesExplainer.explain("Result<Success | Failure, Other>")).to eq(
        "a Result with type parameters ((a Success or a Failure), an Other)"
      )
    end
  end
end
