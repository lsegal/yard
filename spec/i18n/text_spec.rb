# frozen_string_literal: true

RSpec.describe YARD::I18n::Text do
  describe "#extract_messages" do
    def extract_messages(input, options = {})
      text = YARD::I18n::Text.new(StringIO.new(input), options)
      messages = []
      text.extract_messages do |*message|
        messages << message
      end
      messages
    end

    describe "Header" do
      it "extracts at attribute" do
        text = <<-EOT
# @title Getting Started Guide

# Getting Started with YARD
        EOT
        expect(extract_messages(text, :have_header => true)).to eq(
          [[:attribute, "title", "Getting Started Guide", 1],
           [:paragraph, "# Getting Started with YARD", 3]]
        )
      end

      it "ignores markup line" do
        text = <<-EOT
#!markdown
# @title Getting Started Guide

# Getting Started with YARD
        EOT
        expect(extract_messages(text, :have_header => true)).to eq(
          [[:attribute, "title", "Getting Started Guide", 2],
           [:paragraph, "# Getting Started with YARD", 4]]
        )
      end

      it "terminates header block by markup line not at the first line" do
        text = <<-EOT
# @title Getting Started Guide
#!markdown

# Getting Started with YARD
        EOT
        expect(extract_messages(text, :have_header => true)).to eq(
          [[:attribute, "title", "Getting Started Guide", 1],
           [:paragraph, "#!markdown", 2],
           [:paragraph, "# Getting Started with YARD", 4]]
        )
      end
    end

    describe "Body" do
      it "splits to paragraphs" do
        paragraph1 = <<-EOP.strip
Note that class methods must not be referred to with the "::" namespace
separator. Only modules, classes and constants should use "::".
        EOP
        paragraph2 = <<-EOP.strip
You can also do lookups on any installed gems. Just make sure to build the
.yardoc databases for installed gems with:
        EOP
        text = <<-EOT
#{paragraph1}

#{paragraph2}
        EOT
        expect(extract_messages(text)).to eq(
          [[:paragraph, paragraph1, 1],
           [:paragraph, paragraph2, 4]]
        )
      end
    end
  end

  describe "#translate" do
    def locale
      locale = YARD::I18n::Locale.new("fr")
      messages = locale.instance_variable_get(:@messages)
      messages["markdown"] = "markdown (markdown in fr)"
      messages["Hello"] = "Bonjour (Hello in fr)"
      messages["Paragraph 1."] = "Paragraphe 1."
      messages["Paragraph 2."] = "Paragraphe 2."
      locale
    end

    def translate(input, options = {})
      text = YARD::I18n::Text.new(StringIO.new(input), options)
      text.translate(locale)
    end

    describe "Header" do
      it "extracts at attribute" do
        text = <<-EOT
# @title Hello

# Getting Started with YARD

Paragraph.
        EOT
        expect(translate(text, :have_header => true)).to eq <<-EOT
# @title Bonjour (Hello in fr)

# Getting Started with YARD

Paragraph.
        EOT
      end

      it "ignores markup line" do
        text = <<-EOT
#!markdown
# @title Hello

# Getting Started with YARD

Paragraph.
        EOT
        expect(translate(text, :have_header => true)).to eq <<-EOT
#!markdown
# @title Bonjour (Hello in fr)

# Getting Started with YARD

Paragraph.
        EOT
      end
    end

    describe "Body" do
      it "splits to paragraphs" do
        paragraph1 = <<-EOP.strip
Paragraph 1.
        EOP
        paragraph2 = <<-EOP.strip
Paragraph 2.
        EOP
        text = <<-EOT
#{paragraph1}

#{paragraph2}
        EOT
        expect(translate(text)).to eq <<-EOT
Paragraphe 1.

Paragraphe 2.
        EOT
      end

      it "does not modify non-translated message" do
        nonexistent_paragraph = <<-EOP.strip
Nonexsitent paragraph.
        EOP
        text = <<-EOT
#{nonexistent_paragraph}
        EOT
        expect(translate(text)).to eq <<-EOT
#{nonexistent_paragraph}
        EOT
      end

      it "keeps empty lines" do
        text = <<-EOT
Paragraph 1.




Paragraph 2.
        EOT
        expect(translate(text)).to eq <<-EOT
Paragraphe 1.




Paragraphe 2.
        EOT
      end
    end
  end
end
