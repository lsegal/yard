class YARD::Handlers::Ruby::Legacy::ClassHandler < YARD::Handlers::Ruby::Legacy::Base
  include YARD::Handlers::Ruby::StructHandlerMethods
  handles TkCLASS
  
  process do
    if statement.tokens.to_s =~ /^class\s+(#{NAMESPACEMATCH})\s*(?:<\s*(.+)|\Z)/m
      classname = $1
      superclass_def = $2
      superclass = parse_superclass($2)
      undocsuper = $2 && superclass.nil?

      klass = register ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass if superclass
        o.superclass.type = :class if o.superclass.is_a?(Proxy)
      end
      parse_struct_subclass(klass, superclass_def) if superclass =~ /^O?Struct$/
      parse_block(:namespace => klass)
       
      if undocsuper
        raise YARD::Parser::UndocumentableError, 'superclass (class was added without superclass)'
      end
    elsif statement.tokens.to_s =~ /^class\s*<<\s*([\w\:]+)/
      classname = $1
      proxy = Proxy.new(namespace, classname)
      
      # Allow constants to reference class names
      if ConstantObject === proxy
        if proxy.value =~ /\A#{NAMESPACEMATCH}\Z/
          proxy = Proxy.new(namespace, proxy.value)
        else
          raise YARD::Parser::UndocumentableError, "constant class reference '#{classname}'"
        end
      end
      
      if classname == "self"
        parse_block(:namespace => namespace, :scope => :class)
      elsif classname[0,1] =~ /[A-Z]/ 
        register ClassObject.new(namespace, classname) if Proxy === proxy
        parse_block(:namespace => proxy, :scope => :class)
      else
        raise YARD::Parser::UndocumentableError, "class '#{classname}'"
      end
    else
      raise YARD::Parser::UndocumentableError, "class: #{statement.tokens}"
    end
  end
  
  private
  
  ##
  # Extracts the parameter list from the Struct.new declaration and returns it
  # formatted as a list of member names. Expects the user will have used symbols
  # to define the struct member names
  #
  # @param [String] superstring the string declaring the superclass
  # @return [Array<String>] a list of member names
  def extract_parameters(superstring)
    paramstring = superstring.match(/\A(O?Struct)\.new\((.*?)\)/)[2]
    paramstring.split(",").select {|x| x.strip[0,1] == ":"}.map {|x| x.strip[1..-1] } # the 1..-1 chops the leading :
  end
  
  def parse_struct_subclass(klass, superclass_def)
    # Bounce if there's no parens
    return unless superclass_def =~ /O?Struct\.new\((.*?)\)/
    members = extract_parameters(superclass_def)
    create_attributes(klass, members)
  end
  
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