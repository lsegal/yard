class YARD::Handlers::MethodHandler < YARD::Handlers::Base
  handles TkDEF
    
  def process
    nobj = namespace
    mscope = scope
    meth = statement.tokens.to_s[/^def\s+([\s\w\:\.=<>\?^%\/\*\[\]\!]+)/, 1].gsub(/\s+/,'')
    
    # Class method if prefixed by self(::|.) or Module(::|.)
    if meth =~ /(?:#{NSEP}|\.)([^#{NSEP}\.]+)$/
      mscope, meth = :class, $1
      nobj = YARD::Registry.resolve(namespace, $`, true) unless $` == "self"
    end
    
    obj = MethodObject.new(nobj, meth, mscope) do |o|
      o.docstring = statement.comments
      o.signature = statement.tokens.to_s
      o.source = statement
      o.file = parser.file
      o.visibility = visibility
    end
    
    parse_block(:owner => obj) # mainly for yield/exceptions
  end
end