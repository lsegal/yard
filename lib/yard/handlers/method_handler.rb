class YARD::Handlers::MethodHandler < YARD::Handlers::Base
  handles TkDEF
    
  def process
    nobj = namespace
    mscope = scope
    meth = statement.tokens.to_s[/^def\s+(#{METHODMATCH}+)/m, 1].gsub(/\s+/,'')
    
    # Class method if prefixed by self(::|.) or Module(::|.)
    if meth =~ /(?:#{NSEP}|\.)([^#{NSEP}\.]+)$/
      mscope, meth = :class, $1
      nobj = P(namespace, $`) unless $` == "self"
    end
    
    obj = MethodObject.new(nobj, meth, mscope) do |o| 
      o.visibility = visibility 
      o.source = statement
      o.explicit = true
    end
    parse_block(:owner => obj) # mainly for yield/exceptions
    obj # return for registration
  end
end