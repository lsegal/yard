class YARD::Handlers::Ruby::Legacy::MethodHandler < YARD::Handlers::Ruby::Legacy::Base
  handles TkDEF
    
  def process
    nobj = namespace
    mscope = scope

    if statement.tokens.to_s =~ /^def\s+(#{METHODMATCH})(?:(?:\s+|\s*\()(.*)(?:\)\s*$)?)?/m
      meth, args = $1, $2
      meth.gsub!(/\s+/,'')
      args = tokval_list(YARD::Parser::Ruby::Legacy::TokenList.new(args), :all)
      args.map! {|a| k, v = *a.split('=', 2); [k.strip, (v ? v.strip : nil)] } if args
    else
      raise YARD::Parser::UndocumentableError, "method: invalid name"
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
    if mscope == :instance && meth == "initialize"
      unless obj.has_tag?(:return)
        obj.docstring.add_tag(YARD::Tags::Tag.new(:return, 
          "a new instance of #{namespace.name}", namespace.name.to_s))
      end
    elsif mscope == :class && obj.docstring.blank? && %w(inherited included 
        extended method_added method_removed method_undefined).include?(meth)
      obj.docstring.add_tag(YARD::Tags::Tag.new(:private, nil))
    elsif meth.to_s =~ /\?$/
      if obj.tag(:return) && (obj.tag(:return).types || []).empty?
        obj.tag(:return).types = ['Boolean']
      elsif obj.tag(:return).nil?
        obj.docstring.add_tag(YARD::Tags::Tag.new(:return, "", "Boolean"))
      end
    end
    
    if info = obj.attr_info
      if meth.to_s =~ /=$/ # writer
        info[:write] = obj if info[:read]
      else
        info[:read] = obj if info[:write]
      end
    end

    parse_block(:owner => obj) # mainly for yield/exceptions
  end
end
