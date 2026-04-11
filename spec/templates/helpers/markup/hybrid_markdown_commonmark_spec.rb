# frozen_string_literal: true

require 'json'

RSpec.describe YARD::Templates::Helpers::Markup::HybridMarkdown, 'CommonMark 0.31.2 examples' do
  # This suite runs the full upstream CommonMark corpus as a conformance signal.
  # HybridMarkdown is intentionally a hybrid parser, so some failures are
  # expected where YARD/RDoc-compatible behavior deliberately diverges from
  # strict CommonMark, especially around indentation-sensitive block parsing,
  # nested list continuation, and YARD's bare-URL autolinking behavior.
  INTENTIONAL_DIVERGENCE_EXAMPLES = [
    611 # we intentionally auto-link bare URLs.
  ].freeze

  fixture_path = File.dirname(__FILE__) + '/fixtures/commonmark_0.31.2.json'
  all_examples = JSON.parse(File.read(fixture_path), :symbolize_names => true)
  examples = all_examples.reject { |example| INTENTIONAL_DIVERGENCE_EXAMPLES.include?(example[:example]) }

  it 'vendors the full upstream CommonMark corpus' do
    expect(all_examples.length).to eq(652)
  end

  it 'documents the expected hybrid-parser divergences from strict CommonMark' do
    expect(all_examples.count { |example| INTENTIONAL_DIVERGENCE_EXAMPLES.include?(example[:example]) }).to eq(INTENTIONAL_DIVERGENCE_EXAMPLES.length)
  end

  examples.group_by { |example| example[:section] }.sort.each do |section, section_examples|
    describe section do
      section_examples.each do |example|
        it "matches example #{example[:example]} from lines #{example[:start_line]}-#{example[:end_line]}" do
          actual = described_class.new(example[:markdown]).to_html
          expected = example[:html].sub(/\n\z/, '')
          expect(actual).to eq(expected)
        end
      end
    end
  end
end
