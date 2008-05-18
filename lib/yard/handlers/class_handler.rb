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
      classname = $1
      if classname == "self"
        parse_block(:namespace => namespace, :scope => :class)
      elsif classname[0,1] =~ /[A-Z]/
        parse_block(:namespace => P(namespace, classname), :scope => :class)
      else
        raise YARD::Handlers::UndocumentableError, "class '#{klass}'"
      end
    else
      raise YARD::Handlers::UndocumentableError, "class: #{statement.tokens}"
    end
  end
end