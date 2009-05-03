class YARD::Handlers::MethodHandler < YARD::Handlers::Base
  handles TkDEF
    
  def process
    nobj = namespace
    mscope = scope

    if statement.tokens.to_s =~ /^def\s+(#{METHODMATCH})(?:(?:\s+|\s*\()(.*)(?:\)\s*$)?)?/m
      meth, args = $1, $2
      meth.gsub!(/\s+/,'')
      args = tokval_list(YARD::Parser::TokenList.new(args), :all)
      args.map! {|a| k, v = *a.split('=', 2); [k.strip.to_sym, (v ? v.strip : nil)] } if args
    else
      raise YARD::Handlers::UndocumentableError, "method: invalid name"
    end
    
    # Class method if prefixed by self(::|.) or Module(::|.)
    if meth =~ /(?:#{NSEPQ}|#{CSEPQ})([^#{NSEP}#{CSEPQ}]+)$/
      mscope, meth = :class, $1
      nobj = P(namespace, $`) unless $` == "self"
    end
    
    obj = register MethodObject.new(nobj, meth, mscope) do |o| 
      o.visibility = visibility 
      o.source = statement
      o.explicit = true
      o.parameters = args
    end
    parse_block(:owner => obj) # mainly for yield/exceptions
  end
end
