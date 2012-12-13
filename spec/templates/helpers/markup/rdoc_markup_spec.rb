require File.dirname(__FILE__) + "/../../spec_helper"

describe YARD::Templates::Helpers::Markup::RDocMarkup do
  describe 'loading mechanism' do
    before { @good_libs = [] }

    def require(lib)
      return true if @good_libs.include?(lib)
      raise LoadError
    end

    def load_markup
      begin
        require 'rdoc/markup'
        require 'rdoc/markup/to_html'
        return :RDoc2
      rescue LoadError
        begin
          require 'rdoc/markup/simple_markup'
          require 'rdoc/markup/simple_markup/to_html'
          return :RDoc1
        rescue LoadError
          raise NameError, "could not load RDocMarkup (rdoc is not installed)"
        end
      end
    end

    it "should load RDoc2.x if rdoc/markup is present" do
      @good_libs += ['rdoc/markup', 'rdoc/markup/to_html']
      expect(load_markup).to eq :RDoc2
    end

    it "should fail on RDoc2.x if rdoc/markup/to_html is not present" do
      @good_libs += ['rdoc/markup']
      lambda { load_markup }.should raise_error(NameError)
    end

    it "should load RDoc1.x if RDoc2 fails and rdoc/markup/simple_markup is present" do
      @good_libs += ['rdoc/markup/simple_markup', 'rdoc/markup/simple_markup/to_html']
      expect(load_markup).to eq :RDoc1
    end

    it "should error on loading if neither lib is present" do
      lambda { load_markup }.should raise_error(NameError)
    end
  end

  describe '#fix_typewriter' do
    def fix_typewriter(text)
      YARD::Templates::Helpers::Markup::RDocMarkup.new('').send(:fix_typewriter, text)
    end

    it "should use #fix_typewriter to convert +text+ to <tt>text</tt>" do
      expect(fix_typewriter("Some +typewriter text <+.")).to eq "Some <tt>typewriter" + " text &lt;</tt>."
      expect(fix_typewriter("Not +typewriter text.")).to eq "Not +typewriter text."
      expect(fix_typewriter("Alternating +type writer+ text +here+.")).to eq "Alternating <tt>type writer" +
        "</tt> text <tt>here</tt>."
      expect(fix_typewriter("No ++problem.")).to eq "No ++problem."
      expect(fix_typewriter("Math + stuff +is ok+")).to eq "Math + stuff <tt>is ok</tt>"
      expect(fix_typewriter("Hello +{Foo}+ World")).to eq "Hello <tt>{Foo}</tt> World"
    end

    it "should not apply to code blocks" do
      expect(fix_typewriter("<code>Hello +hello+</code>")).to eq "<code>Hello +hello+</code>"
    end

    it "should not apply to HTML tag attributes" do
      expect(fix_typewriter("<a href='http://foo.com/A+b+c'>A+b+c</a>")).to eq "<a href='http://foo.com/A+b+c'>A+b+c</a>"
      expect(fix_typewriter("<foo class='foo+bar+baz'/>")).to eq "<foo class='foo+bar+baz'/>"
    end

    it "should still apply inside of other tags" do
      expect(fix_typewriter("<p>+foo+</p>")).to eq "<p><tt>foo</tt></p>"
    end
  end
end
