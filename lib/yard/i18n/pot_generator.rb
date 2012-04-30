require "stringio"

module YARD
  module I18n
    # The +PotGenerator+ generates POT format string from
    # {CodeObjects::Base} and {CodeObjects::ExtraFileObject}.
    #
    # == POT and PO
    #
    # POT is an acronym for "Portable Object Template". POT is a
    # template file to create PO file. The extension for POT is
    # ".pot". PO file is an acronym for "Portable Object". PO file has
    # many parts of message ID (msgid) that is translation target
    # message and message string (msgstr) that is translated message
    # of message ID. If you want to tranlsate "Hello" in English into
    # "Bonjour" in French, "Hello" is the msgid ID and "Bonjour" is
    # msgstr. The extension for PO is ".po".
    #
    # == How to extract msgids
    #
    # The +PotGenerator+ has two parse methods:
    #
    # * {#parse_objects} for {CodeObjects::Base}
    # * {#parse_files} for {CodeObjects::ExtraFileObject}
    #
    # {#parse_objects} extracts msgids from docstring and tags of
    # {CodeObjects::Base} objects. The docstring of
    # {CodeObjects::Base} object is parsed and a paragraph is
    # extracted as a msgid. Tag name and tag text are extracted as
    # msgids from a tag.
    #
    # {#parse_files} extracts msgids from
    # {CodeObjects::ExtraFileObject} objects. The file content of
    # {CodeObjects::ExtraFileObject} object is parsed and a paragraph
    # is extracted as a msgid.
    #
    # == Usage
    #
    # To create a .pot file by +PotGenerator+, instantiate a
    # +PotGenerator+ with a relative working directory path from a
    # directory path that has created .pot file, parse
    # {CodeObjects::Base} objects and {CodeObjects::ExtraFileObject}
    # objects, generate a POT and write the generated POT to a .pot
    # file. The relative working directory path is ".." when the
    # working directory path is "."  and the POT is wrote into
    # "po/yard.pot".
    #
    # @example Generate a .pot file
    #   po_file_path = "po/yard.pot"
    #   po_file_directory_pathname = Pathname.new(po_file_path).directory)
    #   working_directory_pathname = Pathname.new(".")
    #   relative_base_path = working_directory_pathname.relative_path_from(po_file_directory_pathname).to_s
    #   # relative_base_path -> ".."
    #   generator = YARD::I18n::PotGenerator.new(relative_base_path)
    #   generator.parse_objects(objects)
    #   generator.parse_files(files)
    #   pot = generator.generate
    #   po_file_directory_pathname.mkpath
    #   File.open(po_file_path, "w") do |pot_file|
    #     pot_file.print(pot)
    #   end
    # @see http://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
    #   GNU gettext manual about details of PO file
    class PotGenerator
      # Extracted messages. Key is a translation target message and
      # value is properties of the translation target message. The
      # properties are added to the msgid entry for the translation
      # target message. The properties are +:locations+ and
      # +:comments+.
      #
      # +:locations+ is an array of location. Location is an array of
      # path and line number of the translation target message is
      # appeared. Each location is prepended +:relative_base_path+
      # that is passed on creating a +PotGenerator+ instance.
      #
      # +:comments+ is an array of comment. All comments are added to
      # the msgid entry for the translation target message.
      #
      # @api private
      # @return [Hash{String => Hash{:locations => Array<Array[String, Integer]>, :comments => Array<String>}}]
      attr_reader :messages

      # Creates a POT generator that uses +relative_base_path+ to
      # generate locations for a msgid.
      #
      # @param [String] relative_base_path a relative working
      #   directory path from a directory path that has created .pot
      #   file.
      def initialize(relative_base_path)
        @relative_base_path = relative_base_path
        @extracted_objects = {}
        @messages = {}
      end

      # Parses {CodeObjects::Base} objects and stores extracted msgids
      # into {#messages}
      #
      # @param [Array<CodeObjects::Base>] objects a list of
      #   {CodeObjects::Base} to be parsed.
      # @return [void]
      def parse_objects(objects)
        objects.each do |object|
          extract_documents(object)
        end
      end

      # Parses {CodeObjects::ExtraFileObject} objects and stores
      # extracted msgids into {#messages}.
      #
      # @param [Array<CodeObjects::ExtraFileObject>] files a list
      #   of {CodeObjects::ExtraFileObject} objects to be parsed.
      # @return [void]
      def parse_files(files)
        files.each do |file|
          extract_paragraphs(file)
        end
      end

      # Generates POT from +@messages+.
      #
      # @return [String] POT format string
      def generate
        pot = header
        sorted_messages = @messages.sort_by do |message, options|
          sorted_locations = (options[:locations] || []).sort_by do |location|
            location
          end
          sorted_locations.first || []
        end
        sorted_messages.each do |message, options|
          generate_message(pot, message, options)
        end
        pot
      end

      private
      def header
        <<-'EOH'
# SOME DESCRIPTIVE TITLE.
# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
# This file is distributed under the same license as the PACKAGE package.
# FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
#
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2011-11-20 22:17+0900\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"

EOH
      end

      def generate_message(pot, message, options)
        options[:comments].compact.uniq.each do |comment|
          pot << "# #{comment}\n" unless comment.empty?
        end
        options[:locations].uniq.each do |path, line|
          pot << "#: #{@relative_base_path}/#{path}:#{line}\n"
        end
        escaped_message = escape_message(message)
        escaped_message = escaped_message.gsub(/\n/, "\\\\n\"\n\"")
        pot << "msgid \"#{escaped_message}\"\n"
        pot << "msgstr \"\"\n"
        pot << "\n"
        pot
      end

      def escape_message(message)
        message.gsub(/(\\|")/) do
          special_character = $1
          "\\#{special_character}"
        end
      end

      def add_message(text)
        @messages[text] ||= {:locations => [], :comments => []}
      end

      def extract_documents(object)
        return if @extracted_objects.has_key?(object)

        @extracted_objects[object] = true
        case object
        when CodeObjects::NamespaceObject
          object.children.each do |child|
            extract_documents(child)
          end
        end

        if object.group
          message = add_message(object.group)
          object.files.each do |path, line|
            message[:locations] << [path, line]
          end
          message[:comments] << object.path unless object.path.empty?
        end

        docstring = object.docstring
        unless docstring.empty?
          text = Text.new(StringIO.new(docstring))
          text.extract_messages do |type, *args|
            case type
            when :paragraph
              paragraph, line_no = *args
              message = add_message(paragraph.rstrip)
              object.files.each do |path, line|
                message[:locations] << [path, (docstring.line || line) + line_no]
              end
              message[:comments] << object.path unless object.path.empty?
            else
              raise "should not reach here: unexpected type: #{type}"
            end
          end
        end
        docstring.tags.each do |tag|
          extract_tag_documents(tag)
        end
      end

      def extract_tag_documents(tag)
        extract_tag_name(tag)
        extract_tag_text(tag)
      end

      def extract_tag_name(tag)
        return if tag.name.nil?
        return if tag.name.is_a?(String) and tag.name.empty?
        key = "tag|#{tag.tag_name}|#{tag.name}"
        message = add_message(key)
        tag.object.files.each do |file|
          message[:locations] << file
        end
        tag_label = "@#{tag.tag_name}"
        tag_label << " [#{tag.types.join(', ')}]" if tag.types
        message[:comments] << tag_label
      end

      def extract_tag_text(tag)
        return if tag.text.nil?
        return if tag.text.empty?
        message = add_message(tag.text)
        tag.object.files.each do |file|
          message[:locations] << file
        end
        tag_label = "@#{tag.tag_name}"
        tag_label << " [#{tag.types.join(', ')}]" if tag.types
        tag_label << " #{tag.name}" if tag.name
        message[:comments] << tag_label
      end

      def extract_paragraphs(file)
        File.open(file.filename) do |input|
          text = Text.new(input, :have_header => true)
          text.extract_messages do |type, *args|
            case type
            when :attribute
              name, value, line_no = *args
              message = add_message(value)
              message[:locations] << [file.filename, line_no]
              message[:comments] << name
            when :paragraph
              paragraph, line_no = *args
              message = add_message(paragraph.rstrip)
              message[:locations] << [file.filename, line_no]
            else
              raise "should not reach here: unexpected type: #{type}"
            end
          end
        end
      end
    end
  end
end
