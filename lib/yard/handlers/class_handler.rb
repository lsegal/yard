class YARD::Handlers::ClassHandler < YARD::Handlers::Base
  handles TkCLASS
  
  def process
    if statement.tokens.to_s =~ /^class\s+([\w\:]+)(?:\s*<\s*([\w\:]+))?/
      classname, superclass = $1, $2

      klass = ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass
        o.docstring = statement.comments
        #o.source = statement
        o.line = statement.tokens.first.line_no
        o.file = parser.file
      end
      parse_block(:namespace => klass)
    elsif statement.tokens.to_s =~ /^class\s*<<\s*([\w\:]+)/
      if $1 == "self"
        parse_block(:namespace => namespace, :scope => :class)
      else
        YARD.logger.warn "in ClassHandler: Undocumentable class: '#{$1}'\n"
                    "\tin file '#{parser.file}':#{statement.tokens.first.line_no}"
        return 
      end
    else
      YARD.logger.warn "in ClassHandler: Undocumentable class: #{statement.tokens}\n" +
                  "\tin file '#{parser.file}':#{statement.tokens.first.line_no}"
      return
    end
  end
end