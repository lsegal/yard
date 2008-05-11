class YARD::Handlers::ClassHandler < YARD::Handlers::Base
  handles YARD::Parser::RubyToken::TkCLASS
  
  def process
    if statement.tokens.to_s =~ /^class\s+([\w\:]+)(?:\s*<\s*([\w\:]+))?/
      classname, superclass = $1, $2

      klass = ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass
        o.docstring = statement.comments
        o.source = statement
        o.file = parser.file
      end
      parse_block(klass)
    elsif statement.tokens.to_s =~ /^class\s*<<\s*([\w\:]+)/
      if $1 == "self"
        parse_block(namespace, :class)
      else
        log.warning "in ClassHandler: Undocumentable class: '#{$1}'\n"
                    "\tin file '#{parser.file}':#{statement.tokens.first.line_no}"
        return 
      end
    else
      log.warning "in ClassHandler: Undocumentable class: #{statement.tokens}\n" +
                  "\tin file '#{parser.file}':#{statement.tokens.first.line_no}"
      return
    end
  end
end