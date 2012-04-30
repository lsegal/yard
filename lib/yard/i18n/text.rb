module YARD
  module I18n
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
