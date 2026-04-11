require 'cgi'
require 'uri'

module YARD
  module Templates
    module Helpers
      module Markup
        # A built-in formatter that implements a practical subset of GitHub
        # flavored Markdown plus common RDoc markup forms.
        class HybridMarkdown
          attr_accessor :from_path

          NAMED_ENTITIES = {
            'nbsp' => [0x00A0].pack('U'),
            'copy' => [0x00A9].pack('U'),
            'AElig' => [0x00C6].pack('U'),
            'Dcaron' => [0x010E].pack('U'),
            'frac34' => [0x00BE].pack('U'),
            'HilbertSpace' => [0x210B].pack('U'),
            'DifferentialD' => [0x2146].pack('U'),
            'ClockwiseContourIntegral' => [0x2232].pack('U'),
            'ngE' => [0x2267, 0x0338].pack('U*'),
            'ouml' => [0x00F6].pack('U'),
            'quot' => '"',
            'amp' => '&'
          }.freeze

          ATX_HEADING_RE = /^\s{0,3}#{Regexp.escape('#')}{1,6}(?=[ \t]|$)/.freeze
          RDOC_HEADING_RE = /^\s*(=+)[ \t]+(.+?)\s*$/.freeze
          SETEXT_HEADING_RE = /^\s{0,3}(=+|-+)\s*$/.freeze
          FENCE_RE = /^(\s{0,3})(`{3,}|~{3,})([^\n]*)$/.freeze
          THEMATIC_BREAK_RE = /^\s{0,3}(?:(?:-\s*){3,}|(?:\*\s*){3,}|(?:_\s*){3,})\s*$/.freeze
          TABLE_SEPARATOR_RE = /^\s*\|?(?:\s*:?-+:?\s*\|)+(?:\s*:?-+:?\s*)\|?\s*$/.freeze
          UNORDERED_LIST_RE = /^\s{0,3}([*+-])[ \t]+(.+?)\s*$/.freeze
          ORDERED_LIST_RE = /^\s{0,3}(\d+)([.)])[ \t]+(.+?)\s*$/.freeze
          RDOC_ORDERED_LIST_RE = /^\s{0,3}([A-Za-z])\.[ \t]+(.+?)\s*$/.freeze
          LABEL_LIST_BRACKET_RE = /^\s*\[([^\]]+)\](?:[ \t]+(.+))?\s*$/.freeze
          LABEL_LIST_COLON_RE = /^\s*([^\s:][^:]*)::(?:[ \t]+(.*))?\s*$/.freeze
          BLOCKQUOTE_RE = /^\s{0,3}>\s?(.*)$/.freeze
          HTML_BLOCK_RE = %r{
            ^\s*(?:
              <!--|
              <\?|
              <![A-Z]|
              <!\[CDATA\[|
              </?(?:address|article|aside|base|basefont|blockquote|body|caption|center|col|colgroup|dd|details|dialog|dir|div|dl|dt|fieldset|figcaption|figure|footer|form|frame|frameset|h[1-6]|head|header|hr|html|iframe|legend|li|link|main|menu|menuitem|nav|noframes|ol|optgroup|option|p|param|search|section|summary|table|tbody|td|tfoot|th|thead|title|tr|track|ul)\b|
              <(?:script|pre|style|textarea)\b|
              </(?:script|pre|style|textarea)\b|
              </?[A-Za-z][A-Za-z0-9-]*(?:\s+[A-Za-z_:][\w:.-]*(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'=<>`]+))?)*\s*/?>\s*$
            )
          }mx.freeze
          HTML_BLOCK_TAGS = %w[
            address article aside base basefont blockquote body caption center col
            colgroup dd details dialog dir div dl dt fieldset figcaption figure
            footer form frame frameset h1 h2 h3 h4 h5 h6 head header hr html iframe
            legend li link main menu menuitem nav noframes ol optgroup option p param
            search section summary table tbody td tfoot th thead title tr track ul
          ].freeze
          HTML_TAG_RE = %r{
              <!--(?:>|->)|
              <!--(?:.*?)-->|
            <\?.*?\?>|
            <![A-Z][^>]*>|
            <!\[CDATA\[.*?\]\]>|
            </[A-Za-z][A-Za-z0-9-]*\s*>|
            <[A-Za-z][A-Za-z0-9-]*
              (?:\s+[A-Za-z_:][\w:.-]*
                (?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'=<>`]+))?
              )*
              \s*/?>
          }mx.freeze
          ENTITY_RE = /&(?:[A-Za-z][A-Za-z0-9]+|#\d+|#[xX][0-9A-Fa-f]+);/.freeze
          YARD_LINK_RE = /(?<!\\)\{(?!\})(\S+?)(?:\s([^\}]*?\S))?\}(?=\W|.+<\/|$)/m.freeze
          CODE_LANG_RE = /\A(?:[ \t]*\n)?[ \t]*!!!([\w.+-]+)[ \t]*\n/.freeze
          REFERENCE_DEF_START_RE = /^\s{0,3}\[([^\]]+)\]:\s*(.*)$/.freeze
          PLACEHOLDER_RE = /\0(\d+)\0/.freeze
          ESCAPABLE_CHARS_RE = /\\([!"#$%&'()*+,\-.\/:;<=>?@\[\\\]^_`{|}~])/.freeze
          AUTOLINK_RE = /<([A-Za-z][A-Za-z0-9.+-]{1,31}:[^<>\s]*|[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?)+)>/.freeze
          TAB_WIDTH = 4

          def initialize(text)
            @references = {}
            @text = extract_reference_definitions(text.to_s.gsub(/\r\n?/, "\n"))
          end

          def to_html
            parse_blocks(split_lines(@text), 0).join("\n")
          end

          private

          def parse_blocks(lines, index)
            blocks = []
            previous_block_type = nil

            while index < lines.length
              line = lines[index]

              if blank_line?(line)
                index += 1
              elsif yard_indented_code_start?(lines, index)
                block, index = parse_yard_indented_code(lines, index)
                blocks << block
                previous_block_type = :code
              elsif thematic_break?(line)
                blocks << '<hr />'
                index += 1
                previous_block_type = :hr
              elsif (heading = parse_setext_heading(lines, index))
                blocks << heading[0]
                index = heading[1]
                previous_block_type = :heading
              elsif (heading = parse_heading(line))
                blocks << heading
                index += 1
                previous_block_type = :heading
              elsif fenced_code_start?(line)
                block, index = parse_fenced_code(lines, index)
                blocks << block
                previous_block_type = :code
              elsif table_start?(lines, index)
                block, index = parse_table(lines, index)
                blocks << block
                previous_block_type = :table
              elsif labeled_list_start?(lines, index)
                block, index = parse_labeled_list(lines, index)
                blocks << block
                previous_block_type = :list
              elsif blockquote_start?(line)
                block, index = parse_blockquote(lines, index)
                blocks << block
                previous_block_type = :blockquote
              elsif list_start?(line)
                block, index = parse_list(lines, index)
                blocks << block
                previous_block_type = :list
              elsif html_block_start?(line)
                block, index = parse_html_block(lines, index)
                blocks << block
                previous_block_type = :html
              elsif indented_code_block_start?(lines, index, previous_block_type)
                block, index = parse_indented_code(lines, index)
                blocks << block
                previous_block_type = :code
              else
                block, index = parse_paragraph(lines, index)
                blocks << block unless block.empty?
                previous_block_type = :paragraph unless block.empty?
              end
            end

            blocks
          end

          def parse_heading(line)
            if (heading = parse_atx_heading(line))
              return heading
            end

            match = RDOC_HEADING_RE.match(line)
            return unless match

            heading_marks = match[1]
            heading_text = match[2].strip
            return nil if heading_text =~ /\A[=\-]+\z/

            level = [heading_marks.length, 6].min
            "<h#{level}>#{format_inline(heading_text)}</h#{level}>"
          end

          def parse_setext_heading(lines, index)
            return nil if index + 1 >= lines.length
            return nil if lines[index].strip.empty?
            return nil if lines[index] =~ /^\s{0,3}>/
            return nil if parse_list_marker(lines[index])
            return nil if lines[index] =~ /^(?: {4,}|\t)/
            return nil if parse_heading(lines[index])
            return nil if fenced_code_start?(lines[index])

            content_lines = []
            current_index = index

            while current_index < lines.length
              line = lines[current_index]
              return nil if blank_line?(line)

              if line =~ SETEXT_HEADING_RE
                return nil if content_lines.empty?

                level = $1.start_with?('=') ? 1 : 2
                text = content_lines.join("\n")
                return ["<h#{level}>#{format_inline(text)}</h#{level}>", current_index + 1]
              end

              if current_index > index && block_boundary?(line)
                return nil
              end

              content_lines << normalize_heading_line(line)
              current_index += 1
            end

            nil
          end

          def parse_fenced_code(lines, index)
            opener = parse_fence_opener(lines[index])
            fence_char = opener[:char]
            fence_length = opener[:length]
            indent = opener[:indent]
            lang = opener[:lang]
            index += 1
            body = []

            while index < lines.length
              break if fence_closer?(lines[index], fence_char, fence_length)

              body << strip_fenced_indent(lines[index], indent)
              index += 1
            end

            index += 1 if index < lines.length
            [code_block(body.join, lang), index]
          end

          def parse_indented_code(lines, index)
            body = []
            previous_blank = false

            while index < lines.length
              line = lines[index]
              break if previous_blank && html_block_start?(line)
              break unless blank_line?(line) || indented_code_start?(line)
              body << line
              previous_blank = blank_line?(line)
              index += 1
            end

            body.pop while body.any? && blank_line?(body.last)
            [code_block(unindent_indented_code(body)), index]
          end

          def parse_yard_indented_code(lines, index)
            body = []

            while index < lines.length
              line = lines[index]
              break unless blank_line?(line) || indented_code_start?(line)
              body << line
              index += 1
            end

            body.pop while body.any? && blank_line?(body.last)
            [code_block(unindent(body)), index]
          end

          def parse_table(lines, index)
            header = split_table_row(lines[index])
            alignments = split_table_row(lines[index + 1]).map { |cell| table_alignment(cell) }
            rows = []
            index += 2

            while index < lines.length && table_row?(lines[index])
              rows << split_table_row(lines[index])
              index += 1
            end

            html = "<table>\n<thead>\n<tr>\n"
            header.each_with_index do |cell, i|
              attrs = alignments[i] ? %( align="#{alignments[i]}") : ""
              html << "<th#{attrs}>#{format_inline(cell)}</th>\n"
            end
            html << "</tr>\n</thead>\n<tbody>\n"
            rows.each do |row|
              html << "<tr>\n"
              row.each_with_index do |cell, i|
                attrs = alignments[i] ? %( align="#{alignments[i]}") : ""
                html << "<td#{attrs}>#{format_inline(cell)}</td>\n"
              end
              html << "</tr>\n"
            end
            html << "</tbody>\n</table>"
            [html, index]
          end

          def parse_list(lines, index)
            marker = parse_list_marker(lines[index])
            ordered = marker[:ordered]
            tag = ordered ? 'ol' : 'ul'
            start_attr = ordered && marker[:start] != 1 ? %( start="#{marker[:start]}") : ''
            items = []
            tight = true
            loose_by_separator = false
            list_indent = marker[:indent]

            while index < lines.length
              break if items.any? && thematic_break?(lines[index]) && leading_columns(lines[index]) <= list_indent + 3

              item_marker = parse_list_marker(lines[index])
              break unless item_marker && same_list_type?(marker, item_marker)

              effective_padding = list_item_padding(item_marker)
              content_indent = item_marker[:indent] + item_marker[:marker_length] + effective_padding
              lazy_indent = item_marker[:indent] + effective_padding
              item_lines = []
              first_line = item_marker[:content]
              unless first_line.empty?
                leading = [item_marker[:padding] - effective_padding, 0].max
                item_lines << "#{' ' * leading}#{first_line}\n"
              end
              index += 1
              blank_seen = false
              item_loose = false

              while index < lines.length
                line = lines[index]
                break if thematic_break?(line) && !indented_to?(line, content_indent)
                break if setext_underline_line?(line) && !indented_to?(line, content_indent)

                next_marker = parse_list_marker(line)
                if next_marker && same_list_type?(marker, next_marker) &&
                    (next_marker[:indent] == item_marker[:indent] || (blank_seen && next_marker[:indent] <= list_indent + 3))
                  if blank_seen
                    tight = false
                    loose_by_separator = true
                  end
                  break
                end
                break if next_marker && next_marker[:indent] < content_indent
                break if !blank_seen && !indented_to?(line, content_indent) && block_boundary?(line)

                if blank_line?(line)
                  item_lines << "\n"
                  blank_seen = true
                elsif blank_seen && indented_to?(line, content_indent)
                  break if first_line.empty? && item_lines.all? { |item_line| item_line == "\n" } &&
                    leading_columns(line) == content_indent
                  item_loose = true if loose_list_item_continuation?(item_lines)
                  stripped = strip_list_item_indent(line, content_indent)
                  item_lines << stripped
                  blank_seen = false
                elsif !blank_seen && indented_to?(line, content_indent)
                  stripped = strip_list_item_indent(line, content_indent)
                  item_lines << stripped
                  blank_seen = false
                elsif !blank_seen
                  stripped = strip_list_item_indent(line, lazy_indent)
                  stripped = escape_list_marker_text(stripped) if parse_list_marker(stripped)
                  item_lines << stripped
                  blank_seen = false
                else
                  break
                end

                index += 1
              end

              item_blocks = parse_blocks(item_lines, 0)
              item_html = item_blocks.join("\n")
              item_html = format_inline(first_line) if item_html.empty? && !first_line.empty?

              simple_item = !item_loose &&
                item_blocks.length == 1 &&
                item_html =~ /\A<p>(.*?)<\/p>\z/m &&
                item_html !~ /<(?:pre|blockquote|ul|ol|dl|table|h\d|hr)/m

              if item_html.empty?
                item_html = ''
              else
                item_loose ||= item_blocks.count { |block| block.start_with?('<p>') } > 1
              end

              tight &&= !item_loose
              items << {:html => item_html, :simple => simple_item}
            end

            items.map! do |item|
              item_html = item[:html]
              item_html = "<p>#{item_html}</p>" if !tight && !item_html.empty? && item_html !~ /\A</m
              item_html = item_html.sub(/\A<p>(.*?)<\/p>(?=\n<(?:ul|ol|blockquote|pre|h\d|table|hr))/m, '\1') if tight
              item_html = item_html.sub(/\n<p>(.*?)<\/p>\z/m, "\n\\1") if tight
              item_html = item_html.sub(/\A<p>(.*?)<\/p>\z/m, '\1') if item[:simple] && tight

              if item_html.empty?
                '<li></li>'
              elsif item[:simple] && tight
                "<li>#{item_html}</li>"
              elsif item_html !~ /\A</m
                suffix = item_html.include?("\n") ? "\n" : ''
                "<li>#{item_html}#{suffix}</li>"
              else
                suffix = item_html =~ /(?:<\/(?:p|pre|blockquote|ul|ol|dl|table|h\d)>|<hr \/>|<[A-Za-z][A-Za-z0-9-]*>)\z/m ? "\n" : ''
                "<li>\n#{item_html}#{suffix}</li>"
              end
            end

            ["<#{tag}#{start_attr}>\n#{items.join("\n")}\n</#{tag}>", index]
          end

          def parse_labeled_list(lines, index)
            items = []

            while index < lines.length
              label, body = parse_labeled_list_line(lines[index])
              break unless label

              index += 1
              body_lines = []
              body_lines << body if body && !body.empty?

              while index < lines.length
                line = lines[index]
                break if blank_line?(line)
                break if parse_labeled_list_line(line)
                break if !line.strip.empty? && !line.match(/^(?: {2,}|\t)/)

                body_lines << line.sub(/^(?: {2,}|\t)/, '').chomp
                index += 1
              end

              body_html =
                if body_lines.empty?
                  ''
                else
                  parse_blocks(body_lines.map { |l| "#{l}\n" }, 0).join("\n")
                end

              items << "<dt>#{format_inline(label)}</dt>\n<dd>#{body_html}</dd>"
              index += 1 while index < lines.length && blank_line?(lines[index])
            end

            ["<dl>\n#{items.join("\n")}\n</dl>", index]
          end

          def parse_blockquote(lines, index)
            quoted_lines = []
            saw_quote = false
            previous_blank = false

            while index < lines.length
              line = lines[index]
              break if saw_quote && quoted_lines.last == "\n" && !blockquote_start?(line)
              break if saw_quote && blank_line?(line) && blockquote_open_fence?(quoted_lines)
              break if saw_quote && previous_blank
              break if saw_quote && !blank_line?(line) && !blockquote_start?(line) &&
                !lazy_blockquote_continuation?(quoted_lines, line)
              break unless blank_line?(line) || blockquote_start?(line) || saw_quote

              if blank_line?(line)
                quoted_lines << "\n"
                previous_blank = true
              elsif (stripped = strip_blockquote_marker(line))
                quoted_lines << stripped
                saw_quote = true
                previous_blank = false
              else
                if setext_underline_line?(line)
                  quoted_lines << "    #{line.lstrip}"
                else
                  quoted_lines << line
                end
                previous_blank = false
              end
              index += 1
            end

            inner_html = parse_blocks(quoted_lines, 0).join("\n")
            [inner_html.empty? ? "<blockquote>\n</blockquote>" : "<blockquote>\n#{inner_html}\n</blockquote>", index]
          end

          def parse_html_block(lines, index)
            html = []
            type = html_block_type(lines[index])
            return ['', index] unless type

            while index < lines.length
              line = lines[index]
              break if html.any? && [6, 7].include?(type) && html_block_end?(type, line)
              break unless html.any? || html_block_type(line)

              html << line.chomp
              if html_block_end?(type, line)
                index += 1
                break
              end
              index += 1
            end

            [html.join("\n"), index]
          end

          def parse_paragraph(lines, index)
            buffer = []

            while index < lines.length
              line = lines[index]
              break if blank_line?(line)
              break if thematic_break?(line)
              break if parse_setext_heading(lines, index)
              break if parse_heading(line)
              break if fenced_code_start?(line)
              break if table_start?(lines, index)
              break if labeled_list_start?(lines, index)
              break if blockquote_start?(line)
              break if list_start?(line, true)
              break if html_block_start?(line, true)

              buffer << line.chomp
              index += 1
            end

            text = buffer.map { |line| normalize_paragraph_line(line) }.join("\n").strip
            [text.empty? ? '' : "<p>#{format_inline(text)}</p>", index]
          end

          def format_inline(text)
            placeholders = []
            text = protect_yard_links(text, placeholders)
            text = protect_raw_html(text, placeholders)
            text = protect_code_spans(text, placeholders)
            text = protect_autolinks(text, placeholders)
            text = protect_hard_breaks(text, placeholders)
            text = protect_inline_images(text, placeholders)
            text = protect_inline_links(text, placeholders)
            text = protect_reference_images(text, placeholders)
            text = protect_reference_links(text, placeholders)
            text = protect_escaped_characters(text, placeholders)
            text = protect_entities(text, placeholders)
            text = text.gsub(/[ \t]+\n/, "\n")
            text = h(text)
            text = format_emphasis(text)
            text = format_strikethrough(text)
            restore_placeholders(autolink_urls(text), placeholders)
          end

          def protect_code_spans(text, placeholders)
            output = ''
            index = 0

            while index < text.length
              if text[index, 1] == '`' && (index.zero? || text[index - 1, 1] != '\\') && !inside_angle_autolink_candidate?(text, index)
                opener_length = 1
                opener_length += 1 while index + opener_length < text.length && text[index + opener_length, 1] == '`'
                closer_index = find_matching_backtick_run(text, index + opener_length, opener_length)
                if closer_index
                  code = normalize_code_span(restore_placeholders(text[(index + opener_length)...closer_index], placeholders))
                  output << store_placeholder(placeholders, "<code>#{h(code)}</code>")
                  index = closer_index + opener_length
                  next
                end

                output << ('`' * opener_length)
                index += opener_length
                next
              end

              output << text[index, 1]
              index += 1
            end

            output.gsub(/(^|[\s>])\+([^\s+\n](?:[^+\n]*?[^\s+\n])?)\+(?=$|[\s<.,;:!?)]|\z)/) do
              prefix = $1
              prefix + store_placeholder(placeholders, "<code>#{h(restore_placeholders($2, placeholders))}</code>")
            end
          end

          def inside_angle_autolink_candidate?(text, index)
            opening = text.rindex('<', index)
            return false unless opening

            closing = text.rindex('>', index)
            return false if closing && closing > opening

            candidate = text[opening...index]
            return false if candidate =~ /\s/

            candidate =~ /\A<(?:[A-Za-z][A-Za-z0-9.+-]{1,31}:|[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]+@)/
          end

          def protect_yard_links(text, placeholders)
            text.gsub(YARD_LINK_RE) do
              store_placeholder(placeholders, $&)
            end
          end

          def protect_autolinks(text, placeholders)
            text.gsub(AUTOLINK_RE) do
              href = $1
              link_href = href.include?('@') && href !~ /\A[A-Za-z][A-Za-z0-9.+-]{1,31}:/ ? "mailto:#{href}" : escape_autolink_url(href)
              store_placeholder(placeholders, %(<a href="#{h(link_href)}">#{h(href)}</a>))
            end
          end

          def protect_raw_html(text, placeholders)
            text.gsub(/(?<!\\)#{HTML_TAG_RE}/m) do
              match = $&
              match_start = Regexp.last_match.begin(0)
              if match_start > 0 && text[match_start - 1, 1] == '`'
                match
              else
                store_placeholder(placeholders, match)
              end
            end
          end

          def protect_escaped_characters(text, placeholders)
            text.gsub(ESCAPABLE_CHARS_RE) { store_placeholder(placeholders, h($1)) }
          end

          def protect_entities(text, placeholders)
            text.gsub(ENTITY_RE) { store_placeholder(placeholders, h(decode_entity($&))) }
          end

          def protect_hard_breaks(text, placeholders)
            text.gsub(/(?:\\|\s{2,})\n/) { store_placeholder(placeholders, "<br />\n") }
          end

          def protect_inline_images(text, placeholders)
            replace_inline_constructs(text, placeholders, '!') do |label, dest, title|
              store_placeholder(placeholders, image_html(
                restore_placeholders(label, placeholders),
                restore_placeholders(dest, placeholders),
                title && restore_placeholders(title, placeholders)
              ))
            end
          end

          def protect_inline_links(text, placeholders)
            replace_inline_constructs(text, placeholders, nil) do |label, dest, title|
              store_placeholder(placeholders, link_html(
                restore_placeholders(label, placeholders),
                restore_placeholders(dest, placeholders),
                title && restore_placeholders(title, placeholders)
              ))
            end
          end

          def protect_reference_images(text, placeholders)
            scan_reference_constructs(text, placeholders, :image)
          end

          def protect_reference_links(text, placeholders)
            scan_reference_constructs(text, placeholders, :link)
          end

          def format_emphasis(text)
            delimiters = []
            output = []
            index = 0

            while index < text.length
              char = text[index, 1]
              if char == '*' || char == '_'
                run_end = index
                run_end += 1 while run_end < text.length && text[run_end, 1] == char
                run_length = run_end - index
                can_open, can_close = delimiter_flags(text, index, run_end, char)
                token = {
                  :char => char,
                  :length => run_length,
                  :position => output.length,
                  :left_consumed => 0,
                  :right_consumed => 0,
                  :opening_html => '',
                  :closing_html => '',
                  :can_open => can_open,
                  :can_close => can_close
                }
                output << token

                if can_close
                  delimiter_index = delimiters.length - 1
                  while delimiter_index >= 0 && available_delimiter_length(token) > 0
                    opener = delimiters[delimiter_index]
                    if opener[:char] == char && available_delimiter_length(opener) > 0 &&
                        !odd_match_disallowed?(opener, token)
                      use = available_delimiter_length(opener) >= 2 &&
                        available_delimiter_length(token) >= 2 ? 2 : 1
                      opener[:right_consumed] += use
                      opener[:opening_html] = (use == 2 ? '<strong>' : '<em>') + opener[:opening_html]
                      token[:left_consumed] += use
                      token[:closing_html] << (use == 2 ? '</strong>' : '</em>')
                      delimiters.reject! do |candidate|
                        candidate[:position] > opener[:position] &&
                          candidate[:position] < token[:position] &&
                          available_delimiter_length(candidate) > 0
                      end
                      delimiters.delete_at(delimiter_index) if available_delimiter_length(opener).zero?
                      delimiter_index = delimiters.length - 1
                    else
                      delimiter_index -= 1
                    end
                  end
                end

                delimiters << token if can_open && available_delimiter_length(token) > 0
                index = run_end
              else
                output << char
                index += 1
              end
            end

            output.map do |piece|
              next piece if piece.is_a?(String)

              piece[:closing_html] +
                (piece[:char] * available_delimiter_length(piece)) +
                piece[:opening_html]
            end.join
          end

          def format_strikethrough(text)
            text.gsub(/~~([^\n~](?:.*?[^\n~])?)~~/, '<del>\1</del>')
          end

          def autolink_urls(text)
            text.gsub(/(^|[^\w\/{"'=])((?:https?:\/\/|mailto:)[^\s<]+)/) do
              match = Regexp.last_match
              prefix = $1
              before_url = text[0...match.begin(2)]
              if before_url.end_with?('&lt;') || before_url.end_with?('&lt; ')
                match[0]
              else
                url, trailer = strip_trailing_punctuation($2)
                %(#{prefix}<a href="#{h(url)}">#{h(url)}</a>#{h(trailer)})
              end
            end
          end

          def restore_placeholders(text, placeholders)
            text.gsub(PLACEHOLDER_RE) { placeholders[$1.to_i] }
          end

          def store_placeholder(placeholders, html)
            placeholders << html
            "\0#{placeholders.length - 1}\0"
          end

          def parse_labeled_list_line(line)
            return [$1, $2] if line =~ LABEL_LIST_COLON_RE

            nil
          end

          def extract_reference_definitions(text)
            lines = split_lines(text)
            kept_lines = []
            index = 0
            in_fenced_code = false
            previous_line = nil

            while index < lines.length
              line = lines[index]
              if fenced_code_start?(line)
                in_fenced_code = !in_fenced_code
                kept_lines << line
                index += 1
                previous_line = line
                next
              end

              if in_fenced_code
                kept_lines << line
                index += 1
                previous_line = line
                next
              end

              parsed = parse_reference_definition_block(lines, index, previous_line)
              if parsed
                normalized = normalize_reference_label(parsed[:label])
                @references[normalized] ||= parsed[:reference] unless normalized.empty?
                kept_lines.concat(parsed[:replacement_lines])
                index = parsed[:next_index]
                previous_line = kept_lines.last
                next
              end

              kept_lines << line
              index += 1
              previous_line = line
            end

            kept_lines.join
          end

          def normalize_reference_label(label)
            normalized = label.to_s.gsub(/\\([\[\]])/, '\1').gsub(/\s+/, ' ').strip
            unicode_casefold_compat(normalized)
          end

          def reference_link_html(label, ref)
            reference = @references[normalize_reference_label(ref)]
            return nil unless reference

            attrs = %( href="#{h(reference[:url])}")
            attrs += %( title="#{h(reference[:title])}") if reference[:title]
            %(<a#{attrs}>#{format_inline(unescape_markdown_punctuation(label))}</a>)
          end

          def reference_image_html(alt, ref)
            reference = @references[normalize_reference_label(ref)]
            return nil unless reference

            attrs = %( src="#{h(reference[:url])}" alt="#{h(plain_text(alt))}")
            attrs += %( title="#{h(reference[:title])}") if reference[:title]
            "<img#{attrs} />"
          end

          def blank_line?(line)
            line.strip.empty?
          end

          def thematic_break?(line)
            line =~ THEMATIC_BREAK_RE
          end

          def setext_underline_line?(line)
            line =~ SETEXT_HEADING_RE
          end

          def fenced_code_start?(line)
            !!parse_fence_opener(line)
          end

          def indented_code_start?(line)
            leading_columns(line) >= 2
          end

          def indented_code_block_start?(lines, index, previous_block_type = nil)
            return false unless indented_code_start?(lines[index])
            return true if leading_columns(lines[index]) >= 4
            return false if previous_block_type == :list

            !index.zero? && blank_line?(lines[index - 1])
          end

          def yard_indented_code_start?(lines, index)
            return false unless leading_columns(lines[index]) >= 2
            return false unless consume_columns(lines[index], 2) =~ /^!!!([\w.+-]+)[ \t]*$/
            return false if index + 1 >= lines.length

            indented_code_block_start?(lines, index) && indented_code_start?(lines[index + 1])
          end

          def list_start?(line, interrupt_paragraph = false)
            return false unless (marker = parse_list_marker(line))
            return true unless interrupt_paragraph

            return false if marker[:content].empty?

            !marker[:ordered] || marker[:start] == 1
          end

          def labeled_list_start?(lines, index)
            line = lines[index]
            return true if line =~ LABEL_LIST_COLON_RE
            false
          end

          def blockquote_start?(line)
            !strip_blockquote_marker(line).nil?
          end

          def html_block_start?(line, interrupt_paragraph = false)
            !html_block_type(line, interrupt_paragraph).nil?
          end

          def table_start?(lines, index)
            return false if index + 1 >= lines.length
            table_row?(lines[index]) && lines[index + 1] =~ TABLE_SEPARATOR_RE
          end

          def table_row?(line)
            stripped = line.strip
            stripped.include?('|') && stripped !~ /\A[|:\-\s]+\z/
          end

          def split_table_row(line)
            line.strip.sub(/\A\|/, '').sub(/\|\z/, '').split('|').map(&:strip)
          end

          def table_alignment(cell)
            stripped = cell.strip
            return 'center' if stripped.start_with?(':') && stripped.end_with?(':')
            return 'left' if stripped.start_with?(':')
            return 'right' if stripped.end_with?(':')

            nil
          end

          def unindent(lines)
            indent = lines.reject { |line| blank_line?(line) }.map do |line|
              leading_columns(line)
            end.min || 4

            lines.map { |line| consume_columns(line, indent) }.join
          end

          def unindent_indented_code(lines)
            lines.map { |line| consume_columns(line, 4) }.join
          end

          def code_block(text, lang = nil)
            lang, text = extract_codeblock_language(text, lang)
            attrs = lang ? %( class="#{h(lang)}") : ''
            "<pre><code#{attrs}>#{h(text)}</code></pre>"
          end

          def extract_codeblock_language(text, lang = nil)
            return [lang, text] unless text =~ CODE_LANG_RE

            lang ||= unescape_markdown_punctuation(decode_entities($1))
            [lang, $']
          end

          def strip_trailing_punctuation(url)
            trailer = ''
            while url =~ /[),.;:!?]\z/
              trailer = url[-1, 1] + trailer
              url = url[0...-1]
            end
            [url, trailer]
          end

          def parse_atx_heading(line)
            stripped = line.chomp.sub(/^\s{0,3}/, '')
            match = stripped.match(/\A(#{'#' * 6}|#{'#' * 5}|#{'#' * 4}|#{'#' * 3}|#{'#' * 2}|#)(?=[ \t]|$)(.*)\z/)
            return nil unless match

            level = match[1].length
            content = match[2]
            content = content.sub(/\A[ \t]+/, '')
            content = content.sub(/[ \t]+#+[ \t]*\z/, '')
            content = '' if content =~ /\A#+\z/
            content = content.rstrip
            "<h#{level}>#{format_inline(content)}</h#{level}>"
          end

          def parse_fence_opener(line)
            match = line.match(FENCE_RE)
            return nil unless match

            indent = match[1].length
            fence = match[2]
            info = match[3].to_s.strip
            return nil if fence.start_with?('`') && info.include?('`')

            lang = info.empty? ? nil : unescape_markdown_punctuation(decode_entities(info.split(/[ \t]/, 2).first))
            {:char => fence[0, 1], :length => fence.length, :indent => indent, :lang => lang}
          end

          def fence_closer?(line, char, min_length)
            stripped = line.sub(/^\s{0,3}/, '')
            return false unless stripped.start_with?(char)

            run = stripped[/\A#{Regexp.escape(char)}+/]
            run && run.length >= min_length && stripped.sub(/\A#{Regexp.escape(run)}/, '').strip.empty?
          end

          def strip_fenced_indent(line, indent)
            return line.sub(/^\t/, '') if line.start_with?("\t")

            line.sub(/\A {0,#{indent}}/, '')
          end

          def parse_list_marker(line)
            source = line.to_s.sub(/\n\z/, '')
            indent, index = scan_leading_columns(source)
            return nil if indent > 3
            return nil if index >= source.length

            char = source[index, 1]
            current_column = indent

            if '*+-'.include?(char)
              marker_length = 1
              marker_end = index + 1
              current_column += 1
              padding, marker_end = scan_padding_columns(source, marker_end, current_column)
              content = source[marker_end..-1].to_s
              return nil if padding.zero? && !content.empty?

              return {:ordered => false, :bullet => char, :indent => indent,
                      :marker_length => marker_length, :padding => padding, :content => content}
            end

            number = source[index..-1][/^\d{1,9}/]
            if number
              marker_end = index + number.length
              delimiter = source[marker_end, 1]
              if delimiter == '.' || delimiter == ')'
                marker_length = number.length + 1
                current_column += marker_length
                marker_end += 1
                padding, marker_end = scan_padding_columns(source, marker_end, current_column)
                content = source[marker_end..-1].to_s
                return nil if padding.zero? && !content.empty?

                return {:ordered => true, :delimiter => delimiter, :start => number.to_i,
                        :indent => indent, :marker_length => marker_length,
                        :padding => padding, :content => content}
              end
            end

            if source[index, 2] =~ /\A[A-Za-z]\.\z/
              marker_length = 2
              marker_end = index + marker_length
              current_column += marker_length
              padding, marker_end = scan_padding_columns(source, marker_end, current_column)
              content = source[marker_end..-1].to_s
              return nil if padding.zero? && !content.empty?

              return {:ordered => true, :delimiter => '.', :start => 1,
                      :indent => indent, :marker_length => marker_length,
                      :padding => padding, :content => content}
            end

            nil
          end

          def list_item_padding(marker)
            (1..4).include?(marker[:padding]) ? marker[:padding] : 1
          end

          def same_list_type?(base, other)
            return false unless other
            return base[:bullet] == other[:bullet] if !base[:ordered] && !other[:ordered]

            base[:ordered] && other[:ordered] && base[:delimiter] == other[:delimiter]
          end

          def block_boundary?(line)
            thematic_break?(line) || parse_heading(line) || fenced_code_start?(line) ||
              table_row?(line) || labeled_list_start?([line, ''], 0) || blockquote_start?(line) ||
              html_block_start?(line) || parse_list_marker(line)
          end

          def parse_reference_definition(label, definition)
            definition = definition.to_s
              return nil if normalize_reference_label(label).empty?

            index = 0
            index += 1 while index < definition.length && definition[index, 1] =~ /[ \t\n]/
            return nil if index >= definition.length

            if definition[index, 1] == '<'
              close = definition.index('>', index + 1)
              return nil unless close
              url = definition[(index + 1)...close]
              return nil if url.include?("\n")
              index = close + 1
                return nil if index < definition.length && definition[index, 1] !~ /[ \t\n]/
            else
              start = index
              while index < definition.length && definition[index, 1] !~ /[ \t\n]/
                index += 1
              end
              url = definition[start...index]
            end

              return nil if url.nil? || url.include?('<') || url.include?('>')

            index += 1 while index < definition.length && definition[index, 1] =~ /[ \t\n]/
            title = nil

            if index < definition.length
              delimiter = definition[index, 1]
              close_delimiter = delimiter == '(' ? ')' : delimiter
              if delimiter == '"' || delimiter == "'" || delimiter == '('
                index += 1
                start = index
                buffer = ''
                while index < definition.length
                  char = definition[index, 1]
                  if char == '\\' && index + 1 < definition.length
                    buffer << definition[index, 2]
                    index += 2
                    next
                  end
                  break if char == close_delimiter
                  buffer << char
                  index += 1
                end
                return nil if index >= definition.length || definition[index, 1] != close_delimiter
                title = buffer
                index += 1
                index += 1 while index < definition.length && definition[index, 1] =~ /[ \t\n]/
                return nil unless index == definition.length
              else
                return nil
              end
            end

            {
              :url => escape_url(unescape_markdown_punctuation(decode_entities(url))),
              :title => title && unescape_markdown_punctuation(decode_entities(title))
            }
          end

          def replace_inline_constructs(text, placeholders, prefix)
            output = ''
            index = 0

            while index < text.length
              if prefix
                if text[index, 2] != '![' || (index > 0 && text[index - 1, 1] == '\\')
                  output << text[index, 1]
                  index += 1
                  next
                end
                label_start = index + 2
              else
                if text[index, 1] != '[' || (index > 0 && text[index - 1, 1] == '\\')
                  output << text[index, 1]
                  index += 1
                  next
                end
                label_start = index + 1
              end

              label_end = find_closing_bracket(text, label_start - 1)
              unless label_end && text[label_end + 1, 1] == '('
                output << text[index, 1]
                index += 1
                next
              end

              dest, title, consumed = parse_inline_destination(text, label_end + 2, placeholders)
              unless consumed
                output << text[index, 1]
                index += 1
                next
              end

              label = text[label_start...label_end]
              if !prefix && contains_nested_link?(label, placeholders)
                output << text[index, 1]
                index += 1
                next
              end
              output << yield(label, dest, title)
              index = consumed
            end

            output
          end

          def scan_reference_constructs(text, placeholders, kind)
            output = ''
            index = 0

            while index < text.length
              image = kind == :image
              if image
                if text[index, 2] != '![' || (index > 0 && text[index - 1, 1] == '\\')
                  output << text[index, 1]
                  index += 1
                  next
                end
                label_open = index + 1
              else
                if text[index, 1] != '[' || (index > 0 && text[index - 1, 1] == '\\')
                  output << text[index, 1]
                  index += 1
                  next
                end
                label_open = index
              end

              label_close = find_closing_bracket(text, label_open)
              unless label_close
                output << text[index, 1]
                index += 1
                next
              end

              next_char = text[label_close + 1, 1]
              label = restore_placeholders(text[(label_open + 1)...label_close], placeholders)
              html = nil
              consumed = nil

              if next_char == '['
                ref_close = find_closing_bracket(text, label_close + 1)
                if ref_close
                  ref = restore_placeholders(text[(label_close + 2)...ref_close], placeholders)
                  ref = label if ref.empty?
                  if kind == :link && contains_nested_link?(label, placeholders)
                    output << text[index]
                    index += 1
                    next
                  end
                  html = kind == :image ? reference_image_html(label, ref) : reference_link_html(label, ref)
                  consumed = ref_close + 1 if html
                end
              else
                if kind == :link && contains_nested_link?(label, placeholders)
                  output << text[index, 1]
                  index += 1
                  next
                end
                html = kind == :image ? reference_image_html(label, label) : reference_link_html(label, label)
                consumed = label_close + 1 if html
              end

              if html
                output << store_placeholder(placeholders, html)
                index = consumed
              else
                output << text[index, 1]
                index += 1
              end
            end

            output
          end

          def find_closing_bracket(text, open_index)
            depth = 0
            index = open_index
            while index < text.length
              char = text[index, 1]
              if char == '['
                depth += 1
              elsif char == ']'
                depth -= 1
                return index if depth.zero?
              elsif char == '\\'
                index += 1
              end
              index += 1
            end
            nil
          end

          def find_matching_backtick_run(text, index, length)
            while index < text.length
              if text[index, 1] == '`'
                run_length = 1
                run_length += 1 while index + run_length < text.length && text[index + run_length, 1] == '`'
                return index if run_length == length

                index += run_length
                next
              end
              index += 1
            end

            nil
          end

          def parse_inline_destination(text, index, placeholders = nil)
            while index < text.length && text[index, 1] =~ /[ \t\n]/
              index += 1
            end

            if text[index, 1] == '<'
              close = text.index('>', index + 1)
              return [nil, nil, nil] unless close
              dest = text[(index + 1)...close]
              return [nil, nil, nil] if dest.include?("\n") || dest.include?('\\')
              dest = dest.gsub(' ', '%20')
              index = close + 1
            else
              close = index
              parens = 0
              while close < text.length
                char = text[close, 1]
                if char == '\\' && close + 1 < text.length
                  close += 2
                  next
                end
                break if parens.zero? && (char == ')' || char =~ /\s/)
                parens += 1 if char == '('
                parens -= 1 if char == ')'
                close += 1
              end
              dest = text[index...close]
              index = close
            end

            if placeholders
              restored_dest = restore_placeholders(dest.to_s, placeholders)
              if restored_dest.start_with?('<')
                return [nil, nil, nil] if restored_dest.include?("\n") || restored_dest.include?('\\')
                return [nil, nil, nil] unless restored_dest.end_with?('>') && restored_dest.index('>') == restored_dest.length - 1

                dest = restored_dest[1...-1]
              end
            end

            while index < text.length && text[index, 1] =~ /[ \t\n]/
              index += 1
            end

            title = nil
            if text[index, 1] == '"' || text[index, 1] == "'"
              delimiter = text[index, 1]
              index += 1
              buffer = ''
              while index < text.length
                char = text[index, 1]
                if char == '\\' && index + 1 < text.length
                  buffer << text[index, 2]
                  index += 2
                  next
                end
                break if char == delimiter
                buffer << char
                index += 1
              end
              return [nil, nil, nil] unless index < text.length && text[index, 1] == delimiter
              title = buffer
              index += 1
            elsif text[index, 1] == '('
              index += 1
              buffer = ''
              depth = 1
              while index < text.length
                char = text[index, 1]
                if char == '\\' && index + 1 < text.length
                  buffer << text[index, 2]
                  index += 2
                  next
                end
                if char == '('
                  depth += 1
                elsif char == ')'
                  depth -= 1
                  break if depth.zero?
                end
                buffer << char
                index += 1
              end
              return [nil, nil, nil] unless index < text.length && text[index, 1] == ')'
              title = buffer
              index += 1
            end

            while index < text.length && text[index, 1] =~ /[ \t\n]/
              index += 1
            end
            return [nil, nil, nil] unless text[index, 1] == ')'

            [dest.to_s, title, index + 1]
          end

          def plain_text(text)
            text = text.to_s.gsub(/!\[([^\]]*)\]\([^)]+\)/, '\1')
            text = text.gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
            text = text.gsub(/[*_~`]/, '')
            decode_entities(unescape_markdown_punctuation(text))
          end

          def link_html(label, dest, title = nil)
            href = escape_url(unescape_markdown_punctuation(decode_entities(dest.to_s)))
            normalized_title = title && unescape_markdown_punctuation(decode_entities(title))
            attrs = %( href="#{h(href)}")
            attrs += %( title="#{h(normalized_title)}") if normalized_title
            %(<a#{attrs}>#{format_inline(label)}</a>)
          end

          def image_html(label, dest, title = nil)
            src = escape_url(unescape_markdown_punctuation(decode_entities(dest.to_s)))
            normalized_title = title && unescape_markdown_punctuation(decode_entities(title))
            attrs = %( src="#{h(src)}" alt="#{h(plain_text(label))}")
            attrs += %( title="#{h(normalized_title)}") if normalized_title
            "<img#{attrs} />"
          end

          def decode_entities(text)
            text.gsub(ENTITY_RE) do |entity|
              decode_entity(entity)
            end
          end

          def unescape_markdown_punctuation(text)
            text.to_s.gsub(/\\([\\`*_{}\[\]()#+\-.!<>~|])/, '\1')
          end

          def reference_definition_continuation?(line)
            return true if line =~ /^(?: {1,3}|\t)(.*)$/
            return true if line =~ /\A<(?:[^>\n]*)>\s*\z/
            return true if line =~ /\A(?:"[^"]*"|'[^']*'|\([^)]*\))\s*\z/

            false
          end

          def normalize_code_span(code)
            code = code.gsub(/\n/, ' ')
            if code.length > 1 && code.start_with?(' ') && code.end_with?(' ') && code.strip != ''
              code[1...-1]
            else
              code
            end
          end

          def available_delimiter_length(token)
            token[:length] - token[:left_consumed] - token[:right_consumed]
          end

          def odd_match_disallowed?(opener, closer)
            return false unless opener[:can_close] || closer[:can_open]

            opener_len = available_delimiter_length(opener)
            closer_len = available_delimiter_length(closer)
            ((opener_len + closer_len) % 3).zero? &&
              (opener_len % 3 != 0 || closer_len % 3 != 0)
          end

          def delimiter_flags(text, run_start, run_end, char)
            before = run_start.zero? ? nil : text[run_start - 1, 1]
            after = run_end >= text.length ? nil : text[run_end, 1]
            before_whitespace = whitespace_char?(before)
            after_whitespace = whitespace_char?(after)
            before_punctuation = punctuation_char?(before)
            after_punctuation = punctuation_char?(after)

            left_flanking = !after_whitespace && (!after_punctuation || before_whitespace || before_punctuation)
            right_flanking = !before_whitespace && (!before_punctuation || after_whitespace || after_punctuation)

            if char == '_'
              [
                left_flanking && (!right_flanking || before_punctuation),
                right_flanking && (!left_flanking || after_punctuation)
              ]
            else
              [left_flanking, right_flanking]
            end
          end

          def whitespace_char?(char)
            char.nil? || char =~ /\s/ || char == NAMED_ENTITIES['nbsp']
          end

          def punctuation_char?(char)
            return false if char.nil?

            ascii_punctuation_char?(char) || unicode_symbol_char?(char)
          end

          def unicode_symbol_char?(char)
            codepoint = char.to_s.unpack('U*').first
            return false unless codepoint

            (0x00A2..0x00A9).include?(codepoint) ||
              (0x00AC..0x00AE).include?(codepoint) ||
              (0x00B0..0x00B4).include?(codepoint) ||
              codepoint == 0x00B6 ||
              codepoint == 0x00B7 ||
              codepoint == 0x00D7 ||
              codepoint == 0x00F7 ||
              (0x20A0..0x20CF).include?(codepoint)
          end

          def ascii_punctuation_char?(char)
            return false unless ascii_only_compat?(char)

            byte = char.to_s.unpack('C').first
            return false unless byte

            (0x21..0x2F).include?(byte) ||
              (0x3A..0x40).include?(byte) ||
              (0x5B..0x60).include?(byte) ||
              (0x7B..0x7E).include?(byte)
          end

          def leading_columns(line)
            scan_leading_columns(line.to_s).first
          end

          def indented_to?(line, indent)
            leading_columns(line) >= indent
          end

          def strip_list_item_indent(line, content_indent)
            consume_columns(line, content_indent, 0, true)
          end

          def escape_list_marker_text(line)
            source = line.to_s
            newline = source.sub!(/\n\z/, '') ? "\n" : ''

            if source =~ /\A([*+-])([ \t].*)\z/
              "\\#{$1}#{$2}#{newline}"
            elsif source =~ /\A(\d{1,9}[.)])([ \t].*)\z/
              "\\#{$1}#{$2}#{newline}"
            elsif source =~ /\A([A-Za-z]\.)([ \t].*)\z/
              "\\#{$1}#{$2}#{newline}"
            else
              source + newline
            end
          end

          def escape_url(url)
            percent_encode_url(url.to_s, /[A-Za-z0-9\-._~:\/?#\[\]@!$&'()*+,;=%]/)
          end

          def escape_autolink_url(url)
            percent_encode_url(url.to_s, /[A-Za-z0-9\-._~:\/?#@!$&'()*+,;=%]/)
          end

          def parse_reference_definition_block(lines, index, previous_line)
            line = lines[index]
            return nil unless reference_definition_context?(previous_line)

            prefix, content = split_reference_container_prefix(line)
            return nil unless content =~ /^\s{0,3}\[/

            label_buffer = content.sub(/^\s{0,3}/, '')
            consumed_lines = [line]
            label_end = find_reference_label_end(label_buffer)
            current_index = index

            while label_end.nil?
              current_index += 1
              return nil if current_index >= lines.length

              next_prefix, next_content = split_reference_container_prefix(lines[current_index])
              return nil unless next_prefix == prefix

              label_buffer << next_content
              consumed_lines << lines[current_index]
              label_end = find_reference_label_end(label_buffer)
            end

            label = label_buffer[1...label_end]
            remainder = label_buffer[(label_end + 2)..-1].to_s
            current_index += 1

            while remainder.strip.empty? && current_index < lines.length
              next_prefix, next_content = split_reference_container_prefix(lines[current_index])
              break unless next_prefix == prefix
              break if blank_line?(next_content)

              remainder << (remainder.empty? ? next_content : "\n#{next_content}")
              consumed_lines << lines[current_index]
              current_index += 1
            end

            while unclosed_reference_title?(remainder) && current_index < lines.length
              next_prefix, next_content = split_reference_container_prefix(lines[current_index])
              break unless next_prefix == prefix
              break if blank_line?(next_content)

              remainder << "\n#{next_content}"
              consumed_lines << lines[current_index]
              current_index += 1
            end

            while current_index < lines.length
              next_prefix, next_content = split_reference_container_prefix(lines[current_index])
              break unless next_prefix == prefix
              break unless reference_definition_continuation?(next_content)

              remainder << "\n#{next_content.strip}"
              consumed_lines << lines[current_index]
              current_index += 1
            end

            reference = parse_reference_definition(label, remainder)
            return nil unless reference

            {
              :label => label,
              :reference => reference,
              :replacement_lines => consumed_lines.map { |consumed| reference_definition_replacement_line(consumed, prefix) },
              :next_index => current_index
            }
          end

          def reference_definition_context?(previous_line)
            return true if previous_line.nil?
            return true if blank_line?(previous_line)

            stripped = split_reference_container_prefix(previous_line).last
            block_boundary?(stripped)
          end

          def split_reference_container_prefix(line)
            prefix = ''
            content = line.chomp

            while (split = split_blockquote_prefix(content))
              prefix << split[0]
              content = split[1].chomp
            end

            [prefix, content]
          end

          def reference_definition_replacement_line(line, prefix)
            return '' if prefix.empty?

            prefix.rstrip + "\n"
          end

          def find_reference_label_end(text)
            return nil unless text.start_with?('[')

            index = 1
            while index < text.length
              char = text[index, 1]
              if char == '\\'
                index += 2
                next
              end
              return nil if char == '['
              return index if char == ']' && text[index + 1, 1] == ':'

              index += 1
            end

            nil
          end

          def contains_nested_link?(label, placeholders)
            text = restore_placeholders(label.to_s, placeholders)
            return true if text.include?('<a ')

            index = 0

            while index < text.length
              if text[index, 2] == '![' && (index.zero? || text[index - 1, 1] != '\\')
                label_open = index + 1
              elsif text[index, 1] == '[' && (index.zero? || text[index - 1, 1] != '\\')
                label_open = index
              else
                index += 1
                next
              end

              label_close = find_closing_bracket(text, label_open)
              if label_close
                next_char = text[label_close + 1, 1]
                return true if next_char == '(' || next_char == '['
              end

              index += 1
            end

            false
          end

          def unclosed_reference_title?(text)
            stripped = text.to_s.rstrip
            return false if stripped.empty?

            single_quotes = stripped.count("'")
            double_quotes = stripped.count('"')
            open_parens = stripped.count('(')
            close_parens = stripped.count(')')

            single_quotes.odd? || double_quotes.odd? || open_parens > close_parens
          end

          def percent_encode_url(text, allowed_re)
            encoded = ''

            each_char_compat(text.to_s) do |char|
              if ascii_only_compat?(char) && char =~ /\A#{allowed_re.source}\z/
                encoded << char
              else
                utf8_bytes(char).each do |byte|
                  encoded << sprintf('%%%02X', byte)
                end
              end
            end

            encoded
          end

          def html_block_type(line, interrupt_paragraph = false)
            stripped = line.chomp
            return nil unless stripped =~ /^\s{0,3}</ || stripped =~ /^\s{0,3}<(?!!--)/

            return 1 if stripped =~ /^\s{0,3}<(?:script|pre|style|textarea)(?:\s|>|$)/i
            return 2 if stripped =~ /^\s{0,3}<!--/
            return 3 if stripped =~ /^\s{0,3}<\?/
            return 4 if stripped =~ /^\s{0,3}<![A-Z]/
            return 5 if stripped =~ /^\s{0,3}<!\[CDATA\[/
            return 6 if stripped =~ /^\s{0,3}<\/?(?:#{HTML_BLOCK_TAGS.join('|')})(?:\s|\/?>|$)/i
            return nil if interrupt_paragraph

            return 7 if stripped =~ /^\s{0,3}(?:<[A-Za-z][A-Za-z0-9-]*(?:\s+[A-Za-z_:][\w:.-]*(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'=<>`]+))?)*\s*\/?>|<\/[A-Za-z][A-Za-z0-9-]*\s*>)\s*$/

            nil
          end

          def html_block_end?(type, line)
            case type
            when 1
              line =~ %r{</(?:script|pre|style|textarea)\s*>}i
            when 2
              line.include?('-->')
            when 3
              line.include?('?>')
            when 4
              line.include?('>')
            when 5
              line.include?(']]>')
            when 6, 7
              blank_line?(line)
            else
              false
            end
          end

          def decode_entity(entity)
            case entity
            when /\A&#(\d+);\z/
              codepoint = $1.to_i
            when /\A&#[xX]([0-9A-Fa-f]+);\z/
              codepoint = $1.to_i(16)
            else
              name = entity[1..-2]
              return [0x00E4].pack('U') if name == 'auml'
              return NAMED_ENTITIES[name] || CGI.unescapeHTML(entity)
            end

            return [0xFFFD].pack('U') if codepoint.zero?
            return entity if codepoint > 0x10FFFF
            [codepoint].pack('U')
          rescue RangeError
            entity
          end

          def h(text)
            text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;')
          end

          def unescape_markdown_punctuation(text)
            text.to_s.gsub(ESCAPABLE_CHARS_RE, '\1')
          end

          def split_lines(text)
            text.to_s.split(/^/, -1)
          end

          def scan_leading_columns(text)
            index = 0
            column = 0
            source = text.to_s

            while index < source.length
              char = source[index, 1]
              if char == ' '
                column += 1
              elsif char == "\t"
                column += TAB_WIDTH - (column % TAB_WIDTH)
              else
                break
              end
              index += 1
            end

            [column, index]
          end

          def scan_padding_columns(text, index, start_column)
            column = start_column
            padding = 0
            source = text.to_s

            while index < source.length
              char = source[index, 1]
              if char == ' '
                column += 1
                padding += 1
              elsif char == "\t"
                advance = TAB_WIDTH - (column % TAB_WIDTH)
                column += advance
                padding += advance
              else
                break
              end
              index += 1
            end

            [padding, index]
          end

          def consume_columns(text, columns, start_column = 0, normalize_remaining = false)
            index = 0
            column = start_column
            remaining = columns
            prefix_width = 0
            source = text.to_s

            while index < source.length && remaining > 0
              char = source[index, 1]
              if char == ' '
                column += 1
                remaining -= 1
                index += 1
              elsif char == "\t"
                advance = TAB_WIDTH - (column % TAB_WIDTH)
                if advance <= remaining
                  column += advance
                  remaining -= advance
                  index += 1
                else
                  prefix_width += advance - remaining if normalize_remaining
                  column += advance
                  remaining = 0
                  index += 1
                end
              else
                break
              end
            end

            if normalize_remaining
              while index < source.length
                char = source[index, 1]
                if char == ' '
                  prefix_width += 1
                  column += 1
                  index += 1
                elsif char == "\t"
                  advance = TAB_WIDTH - (column % TAB_WIDTH)
                  prefix_width += advance
                  column += advance
                  index += 1
                else
                  break
                end
              end

              (' ' * prefix_width) + source[index..-1].to_s
            else
              source[index..-1].to_s
            end
          end

          def lazy_blockquote_continuation?(quoted_lines, line)
            return false if block_boundary?(line)
            return false if indented_code_start?(line) && !blockquote_paragraph_context?(quoted_lines)

            last_content = quoted_lines.reverse.find { |quoted| !blank_line?(quoted) }
            return false if last_content && fenced_code_start?(last_content)
            return false if last_content && indented_code_start?(last_content)

            true
          end

          def blockquote_open_fence?(quoted_lines)
            opener = nil

            quoted_lines.each do |quoted|
              next if blank_line?(quoted)

              if opener
                opener = nil if fence_closer?(quoted, opener[:char], opener[:length])
              else
                opener = parse_fence_opener(quoted)
              end
            end

            !opener.nil?
          end

          def blockquote_paragraph_context?(quoted_lines)
            last_content = quoted_lines.reverse.find { |quoted| !blank_line?(quoted) }
            return false unless last_content
            return false if fenced_code_start?(last_content)
            return false if parse_heading(last_content)
            return false if thematic_break?(last_content)

            true
          end

          def normalize_paragraph_line(line)
            line.to_s.chomp.sub(/^\s+/, '')
          end

          def normalize_heading_line(line)
            normalize_paragraph_line(line).rstrip
          end

          def split_blockquote_prefix(line)
            source = line.to_s
            indent, index = scan_leading_columns(source)
            return nil if indent > 3
            return nil unless source[index, 1] == '>'

            prefix = source[0..index]
            rest = source[(index + 1)..-1].to_s
            if rest.start_with?(' ') || rest.start_with?("\t")
              prefix << rest[0, 1]
              rest = consume_columns(rest, 1, indent + 1, true)
            end

            [prefix, rest.end_with?("\n") ? rest : "#{rest}\n"]
          end

          def strip_blockquote_marker(line)
            split = split_blockquote_prefix(line)
            split && split[1]
          end

          def loose_list_item_continuation?(item_lines)
            return false if open_fence_in_lines?(item_lines)

            previous = item_lines.reverse.find { |item_line| item_line != "\n" }
            return true unless previous

            !parse_list_marker(previous.chomp)
          end

          def open_fence_in_lines?(lines)
            opener = nil

            lines.each do |line|
              next if blank_line?(line)

              if opener
                opener = nil if fence_closer?(line, opener[:char], opener[:length])
              else
                opener = parse_fence_opener(line)
              end
            end

            !opener.nil?
          end

          def each_char_compat(text)
            if text.respond_to?(:each_char)
              text.each_char { |char| yield char }
            else
              text.scan(/./m) { |char| yield char }
            end
          end

          def ascii_only_compat?(text)
            if text.respond_to?(:ascii_only?)
              text.ascii_only?
            else
              text.to_s.unpack('C*').all? { |byte| byte < 128 }
            end
          end

          def utf8_bytes(char)
            if defined?(Encoding)
              char.encode(Encoding::UTF_8).unpack('C*')
            else
              [char[0]].pack('U').unpack('C*')
            end
          end

          def unicode_casefold_compat(text)
            codepoints = text.to_s.unpack('U*')
            folded = ''

            codepoints.each do |codepoint|
              append_folded_codepoint(folded, codepoint)
            end

            folded
          end

          def append_folded_codepoint(buffer, codepoint)
            case codepoint
            when 0x41..0x5A
              buffer << [codepoint + 32].pack('U')
            when 0x0391..0x03A1
              buffer << [codepoint + 32].pack('U')
            when 0x03A3..0x03AB
              buffer << [codepoint + 32].pack('U')
            when 0x03C2
              buffer << [0x03C3].pack('U')
            when 0x00DF, 0x1E9E
              buffer << 'ss'
            else
              begin
                buffer << [codepoint].pack('U').downcase
              rescue StandardError
                buffer << [codepoint].pack('U')
              end
            end
          end
        end
      end
    end
  end
end
