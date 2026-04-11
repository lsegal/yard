# frozen_string_literal: true

RSpec.describe YARD::Templates::Helpers::Markup::HybridMarkdown do
  def to_html(text)
    described_class.new(text).to_html.gsub(/\r?\n/, '')
  end

  describe "markdown block syntax" do
    it "renders ATX headings" do
      expect(to_html("## Heading")).to eq('<h2>Heading</h2>')
    end

    it "renders setext headings" do
      expect(to_html("Heading\n---")).to eq('<h2>Heading</h2>')
      expect(to_html("Heading\n===")).to eq('<h1>Heading</h1>')
    end

    it "renders thematic breaks" do
      expect(to_html("---")).to eq('<hr />')
      expect(to_html("* * *")).to eq('<hr />')
    end

    it "renders fenced code blocks" do
      expect(to_html("```ruby\nputs 1\n```")).to eq('<pre><code class="ruby">puts 1</code></pre>')
    end

    it "keeps yard link syntax and macro placeholders literal inside fenced code blocks" do
      html = described_class.new(<<-'MARKDOWN').to_html
```ruby
# @deprecated Use {#my_new_method}
# @return [${-1}] value
```
MARKDOWN
      expect(html).to eq(<<-'HTML'.chomp)
<pre><code class="ruby"># @deprecated Use {#my_new_method}
# @return [${-1}] value
</code></pre>
HTML
    end

    it "renders indented code blocks" do
      expect(to_html("    puts 1\n    puts 2\n")).to eq('<pre><code>puts 1puts 2</code></pre>')
    end

    it "treats two-space indentation as an indented code block after a blank line" do
      expect(to_html("intro\n\n  puts 1\n  puts 2\n")).to eq('<p>intro</p><pre><code>puts 1puts 2</code></pre>')
    end

    it "does not treat two-space indentation as an indented code block without a blank line" do
      expect(to_html("intro\n  puts 1\n  puts 2\n")).to eq('<p>introputs 1puts 2</p>')
    end

    it "treats !!!LANG as the code language for indented blocks" do
      expect(described_class.new("intro\n\n  !!!ruby\n  puts 1\n").to_html).to eq(
        '<p>intro</p>' + "\n" + '<pre><code class="ruby">puts 1' + "\n" + '</code></pre>'
      )
    end

    it "treats indented comment examples as code before heading parsing" do
      html = described_class.new(<<-'MARKDOWN').to_html
    # @deprecated Use {#my_new_method} instead of this method because
    #   it uses a library that is no longer supported in Ruby 1.9.
    #   The new method accepts the same parameters.
MARKDOWN
      expect(html).to eq(<<-'HTML'.chomp)
<pre><code># @deprecated Use {#my_new_method} instead of this method because
#   it uses a library that is no longer supported in Ruby 1.9.
#   The new method accepts the same parameters.
</code></pre>
HTML
    end

    it "renders unordered lists" do
      html = described_class.new("- one\n- two\n").to_html
      expect(html).to include('<ul>')
      expect(html).to include('<li>one</li>')
      expect(html).to include('<li>two</li>')
    end

    it "renders ordered lists" do
      html = described_class.new("1. one\n2. two\n").to_html
      expect(html).to include('<ol>')
      expect(html).to include('<li>one</li>')
      expect(html).to include('<li>two</li>')
    end

    it "renders blockquotes" do
      html = described_class.new("> quoted\n>\n> text\n").to_html.gsub(/\r?\n/, '')
      expect(html).to include('<blockquote>')
      expect(html).to include('<p>quoted</p>')
      expect(html).to include('<p>text</p>')
    end

    it "renders tables with alignment" do
      html = described_class.new("| a | b |\n|:--|--:|\n| 1 | 2 |\n").to_html
      expect(html).to include('<table>')
      expect(html).to include('<th align="left">a</th>')
      expect(html).to include('<th align="right">b</th>')
      expect(html).to include('<td align="right">2</td>')
    end

    it "passes through block HTML" do
      expect(described_class.new("<div>block</div>\n").to_html).to eq('<div>block</div>')
    end
  end

  describe "markdown inline syntax" do
    it "autolinks bare URLs using the full URL as the label" do
      expect(to_html('https://example.com')).to eq(
        '<p><a href="https://example.com">https://example.com</a></p>'
      )
    end

    it "renders inline links" do
      expect(to_html('[YARD](https://yardoc.org)')).to eq(
        '<p><a href="https://yardoc.org">YARD</a></p>'
      )
    end

    it "renders inline images" do
      expect(to_html('![Alt](https://example.com/a.png "Title")')).to eq(
        '<p><img src="https://example.com/a.png" alt="Alt" title="Title" /></p>'
      )
    end

    it "renders full reference-style links" do
      expect(described_class.new("[x][1]\n\n[1]: https://example.com\n").to_html).to eq(
        '<p><a href="https://example.com">x</a></p>'
      )
    end

    it "renders collapsed reference-style links" do
      expect(described_class.new("[x]\n\n[x]: https://example.com\n").to_html).to eq(
        '<p><a href="https://example.com">x</a></p>'
      )
    end

    it "matches reference labels using unicode case folding for greek text" do
      expect(described_class.new("[ΑΓΩ]: /φου\n\n[αγω]\n").to_html).to eq(
        '<p><a href="/%CF%86%CE%BF%CF%85">αγω</a></p>'
      )
    end

    it "matches reference labels using unicode case folding for sharp s" do
      expect(described_class.new("[ẞ]\n\n[SS]: /url\n").to_html).to eq(
        '<p><a href="/url">ẞ</a></p>'
      )
    end

    it "renders reference-style images" do
      expect(described_class.new("![x][logo]\n\n[logo]: https://example.com/logo.png\n").to_html).to eq(
        '<p><img src="https://example.com/logo.png" alt="x" /></p>'
      )
    end

    it "renders strong, emphasis, and strikethrough" do
      expect(to_html('**bold** _em_ ~~gone~~')).to eq(
        '<p><strong>bold</strong> <em>em</em> <del>gone</del></p>'
      )
    end

    it "does not open emphasis around unicode currency symbols" do
      expect(described_class.new("*$*alpha.\n\n*£*bravo.\n\n*€*charlie.\n").to_html).to eq(
        "<p>*$*alpha.</p>\n<p>*£*bravo.</p>\n<p>*€*charlie.</p>"
      )
    end

    it "preserves markdown code spans" do
      expect(to_html('Use `puts 1` here')).to eq('<p>Use <code>puts 1</code> here</p>')
    end

    it "preserves yard link syntax before any markdown parsing" do
      expect(to_html('{MyClass#foo *not bold*}')).to eq('<p>{MyClass#foo *not bold*}</p>')
      expect(to_html('{https://example.com label}')).to eq('<p>{https://example.com label}</p>')
    end

    it "supports hard line breaks" do
      expect(described_class.new("one\\\ntwo").to_html).to eq("<p>one<br />\ntwo</p>")
    end

    it "supports markdown backslash escapes" do
      expect(to_html('\*literal\* \> quote')).to eq('<p>*literal* &gt; quote</p>')
    end

    it "preserves HTML tags inline" do
      expect(to_html('Hello <em>world</em>')).to eq('<p>Hello <em>world</em></p>')
    end

    it "preserves pre-escaped entities" do
      expect(to_html('&amp; &#169;')).to eq('<p>&amp; ©</p>')
    end

    it "escapes HTML-sensitive characters in regular text" do
      expect(to_html('2 < 3 & "quoted"')).to eq('<p>2 &lt; 3 &amp; &quot;quoted&quot;</p>')
    end
  end

  describe "rdoc compatibility" do
    it "renders rdoc headings" do
      expect(to_html("== Heading")).to eq('<h2>Heading</h2>')
    end

    it "renders rdoc typewriter spans" do
      expect(to_html('Hello +<code>+')).to eq('<p>Hello <code>&lt;code&gt;</code></p>')
    end

    it "renders rdoc labeled lists with double colons" do
      html = described_class.new("cat:: feline\ndog:: canine\n").to_html
      expect(html).to include('<dt>cat</dt>')
      expect(html).to include('<dd><p>feline</p></dd>')
    end

    it "does not treat namespace paths using :: as labeled lists" do
      expect(to_html('{YARD::Verifier}')).to eq('<p>{YARD::Verifier}</p>')
      expect(to_html('See YARD::Verifier for details.')).to eq('<p>See YARD::Verifier for details.</p>')
    end

    it "renders alphabetic ordered lists used by rdoc" do
      html = described_class.new("a. first\nb. second\n").to_html
      expect(html).to include('<ol>')
      expect(html).to include('<li>first</li>')
      expect(html).to include('<li>second</li>')
    end

    it "treats two-space indented verbatim text as a code block" do
      expect(to_html("Paragraph\n\n  x = 1\n")).to eq('<p>Paragraph</p><pre><code>x = 1</code></pre>')
    end

    it "treats verbatim text inside nested lists relative to the list indentation" do
      html = described_class.new("- outer\n  - inner\n\n      code\n").to_html
      expect(html).to eq(<<-'HTML'.chomp)
<ul>
<li>outer
<ul>
<li>
<p>inner</p>
<pre><code>code
</code></pre>
</li>
</ul>
</li>
</ul>
HTML
    end

    it "does not treat insufficiently indented text after a list as a verbatim block" do
      expect(described_class.new("-    foo\n\n  bar\n").to_html).to eq(<<-'HTML'.chomp)
<ul>
<li>foo</li>
</ul>
<p>bar</p>
HTML
    end

    it "treats hyphen rules as horizontal rules" do
      expect(to_html("----")).to eq('<hr />')
    end
  end
end
