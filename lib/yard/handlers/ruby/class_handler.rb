class YARD::Handlers::Ruby::ClassHandler < YARD::Handlers::Ruby::Base
  handles :class, :sclass
  
  def process
    if statement.type == :class
      classname = statement[0].source
      superclass = parse_superclass(statement[1])
      undocsuper = statement[1] && superclass.nil?

      klass = register ClassObject.new(namespace, classname) do |o|
        o.superclass = superclass if superclass
        o.superclass.type = :class if o.superclass.is_a?(Proxy)
      end
      parse_block(statement[2], :namespace => klass)
       
      if undocsuper
        raise YARD::Parser::UndocumentableError, 'superclass (class was added without superclass)'
      end
    elsif statement.type == :sclass
      classname = statement[0].source
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
        parse_block(statement[1], namespace: namespace, scope: :class)
      elsif classname[0,1] =~ /[A-Z]/ 
        parse_block(statement[1], namespace: proxy, scope: :class)
      else
        raise YARD::Handlers::UndocumentableError, "class '#{classname}'"
      end
    else
      sig_end = (statement[1] ? statement[1].source_end : statement[0].source_end) - statement.source_start
      raise YARD::Parser::UndocumentableError, "class: #{statement.source[0..sig_end]}"
    end
  end
  
  private
  
  def parse_superclass(superclass)
    return nil unless superclass
    return superclass.source if superclass.ref?
    case superclass.type
    when :const
      superclass.source
    when :call, :command
      superclass[0].source
    when :fcall, :command_call
      superclass.inject("") do |final, component|
        break if component == :"."
        break if component.respond_to?(:type) && component.type != :const
        final << component.to_s
      end
    end
  end
end