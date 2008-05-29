class YARD::Handlers::AliasHandler < YARD::Handlers::Base
  handles /\Aalias_method/
  
  def process
    names, last_tk = [], nil
    statement.tokens[2..-1].each do |tk|
      name = nil
      begin
        if tk.is_a?(TkSTRING)
          name = eval(tk.text)
        elsif (tk.is_a?(TkIDENTIFIER) || tk.is_a?(TkFID)) && last_tk.is_a?(TkSYMBEG)
          name = eval(":" + tk.text)
        end
      rescue SyntaxError, NameError => e
        raise YARD::Handlers::UndocumentableError, "alias_method"
      end
      
      if name
        break if names.push(name).size == 2
      end
      last_tk = tk
    end
    
    new_meth, old_meth = names[0], names[1]
    old_obj = namespace.child(:name => old_meth, :scope => scope)
    new_obj = MethodObject.new(namespace, new_meth, scope) do |o|
      o.visibility = visibility
      o.scope = scope
      o.line = statement.tokens.first.line_no
      o.file = parser.file
      o.docstring = statement.comments
      o.dynamic = true if owner != namespace

      if old_obj
        o.signature = old_obj.signature
        o.source = old_obj.source
      else
        o.signature = "def #{new_meth}"
      end
    end
    
    namespace.aliases[new_obj] = old_meth
  end
end