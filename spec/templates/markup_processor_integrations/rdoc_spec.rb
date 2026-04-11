# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_spec_helper'

RSpec.describe 'RDoc integration' do
  include_context 'shared helpers for markup processor integration specs'

  shared_examples 'shared examples for rdoc processors' do
    let(:markup) { :rdoc }
    let(:document) do
      <<-RDOC
== Example code listings

Verbatim block of Ruby code:

  x = 1

Verbatim non-Ruby block:

  This has nothing to do with Ruby.

RDOC
    end

    it 'renders level 2 header' do
      expect(rendered_document).to match(header_regexp(2, 'Example code listings'))
    end

    it 'renders indented block of code, and applies Ruby syntax highlight' do
      expect(rendered_document).to match(highlighted_ruby_regexp('x', '=', '1'))
    end

    it 'renders indented block of text which is not a piece of Ruby code, ' \
      'and does not apply syntax highlight' do
      expect(rendered_document).to match('This has nothing to do with Ruby.')
    end
  end

  describe 'HybridMarkdown' do
    let(:markup_provider) { :yard }
    include_examples 'shared examples for rdoc processors'
  end

  describe 'RDocMarkup' do
    let(:markup_provider) { :rdoc }
    include_examples 'shared examples for rdoc processors'
  end
end
