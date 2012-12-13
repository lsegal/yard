require File.dirname(__FILE__) + '/spec_helper'

describe YARD::CodeObjects::ExtraFileObject do
  describe '#initialize' do
    it "should attempt to read contents from filesystem if contents=nil" do
      File.should_receive(:read).with('file.txt').and_return('')
      ExtraFileObject.new('file.txt')
    end

    it "should raise Errno::ENOENT if contents=nil and file does not exist" do
      lambda { ExtraFileObject.new('file.txt') }.should raise_error(Errno::ENOENT)
    end

    it "should not attempt to read from disk if contents are provided" do
      ExtraFileObject.new('file.txt', 'CONTENTS')
    end

    it "should set filename to filename" do
      file = ExtraFileObject.new('a/b/c/file.txt', 'CONTENTS')
      expect(file.filename).to eq "a/b/c/file.txt"
    end

    it "should parse out attributes at top of the file" do
      file = ExtraFileObject.new('file.txt', "# @title X\n# @some_attribute Y\nFOO BAR")
      expect(file.attributes[:title]).to eq "X"
      expect(file.attributes[:some_attribute]).to eq "Y"
      expect(file.contents).to eq "FOO BAR"
    end

    it "should allow whitespace prior to '#' marker when parsing attributes" do
      file = ExtraFileObject.new('file.txt', " \t # @title X\nFOO BAR")
      expect(file.attributes[:title]).to eq "X"
      expect(file.contents).to eq "FOO BAR"
    end

    it "should parse out old-style #!markup shebang format" do
      file = ExtraFileObject.new('file.txt', "#!foobar\nHello")
      expect(file.attributes[:markup]).to eq "foobar"
    end

    it "should not parse old-style #!markup if any whitespace is found" do
      file = ExtraFileObject.new('file.txt', " #!foobar\nHello")
      file.attributes[:markup].should be_nil
      expect(file.contents).to eq " #!foobar\nHello"
    end

    it "should not parse out attributes if there are newlines prior to attributes" do
      file = ExtraFileObject.new('file.txt', "\n# @title\nFOO BAR")
      file.attributes.should be_empty
      expect(file.contents).to eq "\n# @title\nFOO BAR"
    end

    it "should set contents to data after attributes" do
      file = ExtraFileObject.new('file.txt', "# @title\nFOO BAR")
      expect(file.contents).to eq "FOO BAR"
    end

    it "should preserve newlines" do
      file = ExtraFileObject.new('file.txt', "FOO\r\nBAR\nBAZ")
      expect(file.contents).to eq "FOO\r\nBAR\nBAZ"
    end

    it "should not include newlines in attribute data" do
      file = ExtraFileObject.new('file.txt', "# @title FooBar\r\nHello world")
      expect(file.attributes[:title]).to eq "FooBar"
    end

    it "should force encoding to @encoding attribute if present" do
      log.should_not_receive(:warn)
      data = "# @encoding sjis\nFOO"
      data.force_encoding('binary')
      file = ExtraFileObject.new('file.txt', data)
      ['Shift_JIS', 'Windows-31J'].should include(file.contents.encoding.to_s)
    end if YARD.ruby19?

    it "should warn if @encoding is invalid" do
      log.should_receive(:warn).with("Invalid encoding `INVALID' in file.txt")
      data = "# @encoding INVALID\nFOO"
      encoding = data.encoding
      file = ExtraFileObject.new('file.txt', data)
      expect(file.contents.encoding).to eq encoding
    end if YARD.ruby19?

    it "should ignore encoding in 1.8.x (or encoding-unaware platforms)" do
      log.should_not_receive(:warn)
      ExtraFileObject.new('file.txt', "# @encoding INVALID\nFOO")
    end if YARD.ruby18?

    it "should attempt to re-parse data as 8bit ascii if parsing fails" do
      log.should_not_receive(:warn)
      str = "\xB0"
      str.force_encoding('utf-8') if str.respond_to?(:force_encoding)
      file = ExtraFileObject.new('file.txt', str)
      expect(file.contents).to eq "\xB0"
    end
  end

  describe '#name' do
    it "should be set to basename (not extension) of filename" do
      file = ExtraFileObject.new('file.txt', '')
      expect(file.name).to eq 'file'
    end
  end

  describe '#title' do
    it "should return @title attribute if present" do
      file = ExtraFileObject.new('file.txt', '# @title FOO')
      expect(file.title).to eq 'FOO'
    end

    it "should return #name if no @title attribute exists" do
      file = ExtraFileObject.new('file.txt', '')
      expect(file.title).to eq 'file'
    end
  end

  describe '#locale=' do
    it "should translate contents" do
      file = ExtraFileObject.new('file.txt', 'Hello')
      file.locale = 'fr'
      fr_locale = I18n::Locale.new('fr')
      fr_messages = fr_locale.instance_variable_get(:@messages)
      fr_messages["Hello"] = 'Bonjour'
      Registry.should_receive(:locale).with('fr').and_return(fr_locale)
      expect(file.contents).to eq 'Bonjour'
    end
  end

  describe '#==' do
    it "should define equality on filename alone" do
      file1 = ExtraFileObject.new('file.txt', 'A')
      file2 = ExtraFileObject.new('file.txt', 'B')
      expect(file1).to eq file2
      file1.should be_eql(file2)
      file1.should be_equal(file2)

      # Another way to test the equality interface
      a = [file1]
      a |= [file2]
      expect(a.size).to eq 1
    end

  end
end
