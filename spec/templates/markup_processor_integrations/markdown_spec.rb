# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_spec_helper'

RSpec.describe 'Markdown processors integration' do
  include_context 'shared helpers for markup processor integration specs'

  shared_examples 'shared examples for markdown processors' do
    let(:document) do
    <<-MARKDOWN
## Example code listings

Indented block of Ruby code:

    x = 1

Fenced block of Ruby code:

```
x = 2
```

Fenced and annotated block of Ruby code:

```ruby
x = 3
```

Fenced and annotated block of non-Ruby code:

```plain
x = 4
```

### Example line break

commonmark line break with\\
a backslash
MARKDOWN
    end

    it 'renders level 2 header' do
      expect(rendered_document).to match(header_regexp(2, 'Example code listings'))
    end

    it 'renders indented block of code, and applies Ruby syntax highlight' do
      expect(rendered_document).to match(highlighted_ruby_regexp('x', '=', '1'))
    end

    it 'renders fenced block of code, and applies Ruby syntax highlight' do
      expect(rendered_document).to match(highlighted_ruby_regexp('x', '=', '2'))
    end

    it 'renders fenced and annotated block of Ruby code, and applies syntax highlight' do
      expect(rendered_document).to match(highlighted_ruby_regexp('x', '=', '3'))
    end

    it 'renders fenced and annotated block of non-Ruby code, and does not apply syntax highlight' do
      expect(rendered_document).to match('x = 4')
    end

    it "autolinks URLs" do
      expect(html_renderer.htmlify('http://example.com', :markdown).chomp.gsub('&#47;', '/')).to eq(
        '<p><a href="http://example.com">http://example.com</a></p>'
      )
    end
  end

  describe 'Redcarpet' do
    let(:markup) { :markdown }
    let(:markup_provider) { :redcarpet }

    include_examples 'shared examples for markdown processors'


    it 'generates anchor tags for level 2 header' do
      expect(rendered_document).to include('<h2 id="example-code-listings">Example code listings</h2>')
    end

    it 'does not create line break via backslash' do
      expect(rendered_document).to include("commonmark line break with\\\na backslash")
    end
  end

  describe 'CommonMarker', if:  RUBY_VERSION >= '2.3' do
    let(:markup) { :markdown }
    let(:markup_provider) { :commonmarker }

    include_examples 'shared examples for markdown processors'

    it 'generates level 2 header without id' do
      expect(rendered_document).to include('<h2>Example code listings</h2>')
    end

    it 'creates line break via backslash' do
      expect(rendered_document).to include("commonmark line break with<br />\na backslash")
    end
  end
end
