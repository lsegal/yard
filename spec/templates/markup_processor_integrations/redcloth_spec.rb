# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_spec_helper'

RSpec.describe 'RedCloth integration' do
  include_context 'shared helpers for markup processor integration specs'
  let(:markup) { :textile }
  let(:markup_provider) { :redcloth }

  let(:document) do
    <<-TEXTILE
h2. Example code listings

Example paragraph.

p. Example paragraph using 'p' tag.

p. Block of Ruby code using 'bc' tag:

bc. x = 1

p. Block of Ruby code using 'pre' tag:

pre. x = 2
TEXTILE
  end

  it 'renders level 2 header' do
    expect(rendered_document).to match(header_regexp(2, 'Example code listings'))
  end

  it 'renders paragraphs' do
    expect(rendered_document).
      to include('<p>Example paragraph.</p>')
    # Textile may replace typewriter apostrophes here used as quotes with
    # something typographically better
    expect(rendered_document).
      to match(%r{<p>Example paragraph using .*p.* tag.</p>})
  end

  it 'renders bc. block, and applies Ruby syntax highlight' do
    expect(rendered_document).to match(highlighted_ruby_regexp('x', '=', '1'))
  end

  it 'renders pre. block, and applies Ruby syntax highlight' do
    expect(rendered_document).to match(highlighted_ruby_regexp('x', '=', '2'))
  end
end
