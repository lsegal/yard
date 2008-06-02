class YARD::Handlers::ClassHandler < YARD::Handlers::Base
  handles TkCLASS
  
  def process
    if statement.tokens.to_s =~ /^class\s+(#{NAMESPACEMATCH})(\s*<.+|\s*\Z)/m
      classname, extra, superclass, undocsuper = $1, $2, nil, false
      if extra =~ /\A\s*<\s*/m
        superclass = extra[/\A\s*<\s*(#{NAMESPACEMATCH})\s*\Z/m, 1]
        undocsuper = true if superclass.nil?
      end

      klass = ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass if superclass
        o.superclass.type = :class if o.superclass.is_a?(Proxy)
      end
      parse_block(:namespace => klass)
      register klass # Explicit registration
       
      if undocsuper
        raise YARD::Handlers::UndocumentableError, 'added class, but cannot document superclass'
      end
    elsif statement.tokens.to_s =~ /^class\s*<<\s*([\w\:]+)/m
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