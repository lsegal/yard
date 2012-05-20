require "tmpdir"

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
      locale("fr").name.should == "fr"
    end
  end

  describe "#load" do
    it "should return false for nonexistent PO" do
      @locale.load("nonexistent-locale-directory").should == false
    end

    it "should return true for existent PO" do
      Dir.mktmpdir do |locale_directory|
        po_path = "#{locale_directory}/fr.po"
        File.open(po_path, "w") do |po|
          po.puts(<<-eop)
msgid ""
msgstr ""
"Language: fr\n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

msgid "Hello"
msgstr "Bonjour"
eop
        end
        @locale.load(locale_directory).should == true
      end
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
