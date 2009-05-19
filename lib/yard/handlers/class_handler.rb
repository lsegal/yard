class YARD::Handlers::ClassHandler < YARD::Handlers::Ruby::Legacy::Base
  handles TkCLASS
  
  def process
    if statement.tokens.to_s =~ /^class\s+(#{NAMESPACEMATCH})\s*(?:<\s*(.+)|\Z)/m
      classname = $1
      superclass = parse_superclass($2)
      undocsuper = $2 && superclass.nil?

      klass = register ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass if superclass
        o.superclass.type = :class if o.superclass.is_a?(Proxy)
      end
      parse_block(:namespace => klass)
       
      if undocsuper
        raise YARD::Handlers::UndocumentableError, 'superclass (class was added without superclass)'
      end
    elsif statement.tokens.to_s =~ /^class\s*<<\s*([\w\:]+)/
      classname = $1
      proxy = Proxy.new(namespace, classname)
      
      # Allow constants to reference class names
      if ConstantObject === proxy
        if proxy.value =~ /\A#{NAMESPACEMATCH}\Z/
          proxy = Proxy.new(namespace, proxy.value)
        else
          raise YARD::Handlers::UndocumentableError, "constant class reference '#{classname}'"
        end
      end
      
      if classname == "self"
        parse_block(:namespace => namespace, :scope => :class)
      elsif classname[0,1] =~ /[A-Z]/ 
        parse_block(:namespace => proxy, :scope => :class)
      else
        raise YARD::Handlers::UndocumentableError, "class '#{classname}'"
      end
    else
      raise YARD::Handlers::UndocumentableError, "class: #{statement.tokens}"
    end
  end
  
  private
  
  def parse_superclass(superclass)
    case superclass
    when /\A(#{NAMESPACEMATCH})(?:\s|\Z)/, 
         /\A(Struct|OStruct)\.new/,
         /\ADelegateClass\((.+?)\)\s*\Z/,
         /\A(#{NAMESPACEMATCH})\(/
      $1
    end
  end
end