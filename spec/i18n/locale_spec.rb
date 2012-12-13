require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::I18n::Locale do
  def locale(name)
    YARD::I18n::Locale.new(name)
  end

  before do
    @locale = locale("fr")
  end

  describe "#name" do
    it "should return name" do
      expect(locale("fr").name).to eq "fr"
    end
  end

  describe "#load" do
    it "should return false for nonexistent PO" do
      File.should_receive(:exist?).with('foo/fr.po').and_return(false)
      expect(@locale.load('foo')).to eq false
    end

    have_gettext_gem = true
    begin
      require "gettext/tools/poparser"
    rescue LoadError
      have_gettext_gem = false
    end
    it "should return true for existent PO", :if => have_gettext_gem do
      data = <<-eop
msgid ""
msgstr ""
"Language: fr\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

msgid "Hello"
msgstr "Bonjour"
eop
      parser = GetText::PoParser.new
      File.should_receive(:exist?).with('foo/fr.po').and_return(true)
      GetText::PoParser.should_receive(:new).and_return(parser)
      parser.should_receive(:parse_file) do |file, hash|
        expect(file).to eq 'foo/fr.po'
        parser.parse(data, hash)
      end
      expect(@locale.load('foo')).to eq true
      expect(@locale.translate('Hello')).to eq "Bonjour"
    end
  end

  describe "#translate" do
    before do
      messages = @locale.instance_variable_get(:@messages)
      messages["Hello"] = "Bonjour"
    end

    it "should return translated string for existent string" do
      @locale.translate("Hello") == "Bonjour"
    end

    it "should return original string for nonexistent string" do
      @locale.translate("nonexistent") == "nonexistent"
    end
  end
end
