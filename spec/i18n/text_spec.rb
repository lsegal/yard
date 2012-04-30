describe YARD::I18n::Text do
  def extract_messages(input, options={})
    text = YARD::I18n::Text.new(StringIO.new(input), options)
    messages = []
    text.extract_messages do |*message|
      messages << message
    end
    messages
  end

  describe "Header" do
    it "should extract attribute" do
      text = <<-eot
# @title Getting Started Guide

# Getting Started with YARD
eot
      extract_messages(text, :have_header => true).should ==
        [[:attribute, "title", "Getting Started Guide", 1],
         [:paragraph, "# Getting Started with YARD", 3]]
    end

    it "should ignore markup line" do
      text = <<-eot
#!markdown
# @title Getting Started Guide

# Getting Started with YARD
eot
      extract_messages(text, :have_header => true).should ==
        [[:attribute, "title", "Getting Started Guide", 2],
         [:paragraph, "# Getting Started with YARD", 4]]
    end

    it "should terminate header block by markup line not at the first line" do
      text = <<-eot
# @title Getting Started Guide
#!markdown

# Getting Started with YARD
eot
      extract_messages(text, :have_header => true).should ==
        [[:attribute, "title", "Getting Started Guide", 1],
         [:paragraph, "#!markdown", 2],
         [:paragraph, "# Getting Started with YARD", 4]]
    end
  end

  describe "Body" do
    it "should split to paragraphs" do
      paragraph1 = <<-eop.strip
Note that class methods must not be referred to with the "::" namespace
separator. Only modules, classes and constants should use "::".
eop
      paragraph2 = <<-eop.strip
You can also do lookups on any installed gems. Just make sure to build the
.yardoc databases for installed gems with:
eop
      text = <<-eot
#{paragraph1}

#{paragraph2}
eot
      extract_messages(text).should ==
        [[:paragraph, paragraph1, 1],
         [:paragraph, paragraph2, 4]]
    end
  end
end
