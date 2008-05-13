class YARD::Handlers::MethodHandler < YARD::Handlers::Base
  handles TkDEF
    
  def process
    mscope = scope
    meth = statement.tokens.to_s[/^def\s+([\s\w\:\.=<>\?^%\/\*]+)/, 1].gsub(/\s+/,'')
    
    # Class method if prefixed by self(::|.) or Module(::|.)
    if meth =~ /(?:#{NSEP}|\.)([^#{NSEP}\.]+)$/
      mscope, meth = :class, $1
      nobj = Registry.resolve(namespace, $`, true) unless $` == "self"
    end
    
    obj = MethodObject.new(namespace, meth, mscope) do |o|
      o.docstring = statement.comments
      o.source = statement
      o.file = parser.file
      o.visibility = visibility
    end
    
    parse_block(:owner => obj) # mainly for yield/exceptions
  end
end