module YARD
  module I18n
    # Provides some convenient features for translating a text.
    class Text
      # Creates a text object that has translation related features for
      # the input text.
      #
      # @param [#each_line] input a text to be translated.
      # @option options [Boolean] :have_header (false) whether the
      #   input text has header or not.
      def initialize(input, options={})
        @input = input
        @options = options
      end

      # Extracts translation target messages from +@input+.
      #
      # @yield [:attribute, name, value, line_no] the block that
      #   recieves extracted an attribute in header. It may called many
      #   times.
      # @yieldparam [String] name the name of extracted attribute.
      # @yieldparam [String] value the value of extracted attribute.
      # @yieldparam [Integer] line_no the defined line number of extracted
      #   attribute.
      # @yield [:paragraph, text, start_line_no] the block that
      #   recieves extracted a paragraph in body. Paragraph is a text
      #   block separated by one or more empty lines. Empty line is a
      #   line that contains only zero or more whitespaces. It may
      #   called many times.
      # @yieldparam [String] text the text of extracted paragraph.
      # @yieldparam [Integer] start_line_no the start line number of
      #   extracted paragraph.
      # @return [void]
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
