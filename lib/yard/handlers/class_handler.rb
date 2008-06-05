class YARD::Handlers::ClassHandler < YARD::Handlers::Base
  handles TkCLASS
  
  def process
    if statement.tokens.to_s =~ /^class\s+(#{NAMESPACEMATCH})\s*(<.+|\Z)/m
      classname, extra, superclass, undocsuper = $1, $2, nil, false
      if extra =~ /\A\s*<\s*/
        superclass = extra[/\A\s*<\s*(#{NAMESPACEMATCH})\s*\Z/, 1]
        undocsuper = true if superclass.nil?
      end

      register klass = ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass if superclass
        o.superclass.type = :class if o.superclass.is_a?(Proxy)
      end
      parse_block(:namespace => klass)
       
      if undocsuper
        raise YARD::Handlers::UndocumentableError, 'superclass (class was added without superclass)'
      end
    elsif statement.tokens.to_s =~ /^class\s*<<\s*([\w\:]+)/
      classname = $1
      if classname == "self"
        parse_block(:namespace => namespace, :scope => :class)
      elsif classname[0,1] =~ /[A-Z]/
        parse_block(:namespace => P(namespace, classname), :scope => :class)
      else
        raise YARD::Handlers::UndocumentableError, "class '#{classname}'"
      end
    else
      raise YARD::Handlers::UndocumentableError, "class: #{statement.tokens}"
    end
  end
end