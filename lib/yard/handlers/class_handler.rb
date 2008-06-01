class YARD::Handlers::ClassHandler < YARD::Handlers::Base
  handles TkCLASS
  
  def process
    if statement.tokens.to_s =~ /^class\s+(#{NAMESPACEMATCH})(?:\s*<\s*(#{NAMESPACEMATCH}))?\s*\Z/
      classname, superclass = $1, $2

      klass = ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass if superclass
        o.superclass.type = :class if o.superclass.is_a?(Proxy)
      end
      parse_block(:namespace => klass)
      register klass # Explicit registration
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