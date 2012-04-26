require "pathname"
require "stringio"

module YARD
  module CLI
    # CLI command to support internationalization (a.k.a. i18n).
    # I18n feature is based on gettext technology.
    # This command generates .pot file from docstring and extra
    # documentation.
    #
    # @since 0.8.0
    # @todo Support msgminit and msgmerge features?
    class I18n < Yardoc
      def initialize
        super
        @options.serializer.basepath = "po/yard.pot"
      end

      def description
        'Generates .pot file from source code and extra documentation'
      end

      def run(*args)
        if args.size == 0 || !args.first.nil?
          # fail early if arguments are not valid
          return unless parse_arguments(*args)
        end

        YARD.parse(files, excluded)

        serializer = options.serializer
        pot_file_path = Pathname.new(serializer.basepath).expand_path
        pot_file_dir_path, pot_file_basename = pot_file_path.split
        relative_base_path = Pathname.pwd.relative_path_from(pot_file_dir_path)
        serializer.basepath = pot_file_dir_path.to_s
        serializer.serialize(pot_file_basename.to_s,
                             generate_pot(relative_base_path.to_s))

        true
      end

      private

      def general_options(opts)
        opts.banner = "Usage: yard i18n [options] [source_files [- extra_files]]"
        opts.top.list.clear
        opts.separator "(if a list of source files is omitted, "
        opts.separator "  {lib,app}/**/*.rb ext/**/*.c is used.)"
        opts.separator ""
        opts.separator "Example: yard i18n -o yard.pot - FAQ LICENSE"
        opts.separator "  The above example outputs .pot file for files in"
        opts.separator "  lib/**/*.rb to yard.pot including the extra files"
        opts.separator "  FAQ and LICENSE."
        opts.separator ""
        opts.separator "A base set of options can be specified by adding a .yardopts"
        opts.separator "file to your base path containing all extra options separated"
        opts.separator "by whitespace."
        super(opts)
      end

      def generate_pot(relative_base_path)
        generator = PotGenerator.new(relative_base_path)
        objects = run_verifier(all_objects)
        generator.parse_objects(objects)
        generator.parse_files(options.files || [])
        generator.generate
      end

      # @private
      class PotGenerator
        attr_reader :messages
        def initialize(relative_base_path)
          @relative_base_path = relative_base_path
          @extracted_objects = {}
          @messages = {}
        end

        def parse_objects(objects)
          objects.each do |object|
            extract_documents(object)
          end
        end

        def parse_files(files)
          files.each do |file|
            extract_paragraphs(file)
          end
        end

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

      # @private
      class Text
        def initialize(input, options={})
          @input = input
          @options = options
        end

        def extract_messages
          paragraph = ""
          paragraph_start_line = 0
          line_no = 0
          in_header = @options[:have_header]

          @input.each_line do |line|
            line_no += 1
            if in_header
              case line
              when /^#!\S+\s*$/
                in_header = false unless line_no == 1
              when /^\s*#\s*@(\S+)\s*(.+?)\s*$/
                name, value = $1, $2
                yield(:attribute, name, value, line_no)
              else
                in_header = false
                next if line.chomp.empty?
              end
              next if in_header
            end

            case line
            when /^\s*$/
              next if paragraph.empty?
              yield(:paragraph, paragraph.rstrip, paragraph_start_line)
              paragraph = ""
            else
              paragraph_start_line = line_no if paragraph.empty?
              paragraph << line
            end
          end
          unless paragraph.empty?
            yield(:paragraph, paragraph.rstrip, paragraph_start_line)
          end
        end
      end
    end
  end
end
