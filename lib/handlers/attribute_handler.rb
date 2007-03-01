class YARD::AttributeHandler < YARD::CodeObjectHandler
  handles /\Aattr(_(reader|writer|accessor))?\b/
  
  def process
    attr_type   = statement.tokens.first.text.to_sym
    symbols     = eval("[" + statement.tokens[1..-1].to_s + "]")
    read, write = true, false
    
    # Change read/write based on attr_reader/writer/accessor
    case attr_type
    when :attr
      # In the case of 'attr', the second parameter (if given) isn't a symbol.
      read = symbols.pop if symbols.size == 2
    when :attr_accessor
      write = true
    when :attr_reader
      # change nothing
    when :attr_writer
      read, write = false, true
    end

    # Add all attributes
    symbols.each do |name| 
      name = name.to_s
      object[:attributes].update(name.to_s => { :read => read, :write => write })

      # Show their methods as well
      [name, "#{name}="].each do |method|
        YARD::MethodObject.new(method, current_visibility, current_scope, object, statement.comments) do |obj|
          if method.to_s.include? "="
            src = "def #{method}(value)"
            full_src = "#{src}\n  @#{name} = value\nend"
            doc = "Sets the attribute +#{name}+\n@param value the value to set the attribute +#{name}+ to."
          else
            src = "def #{method}"
            full_src = "#{src}\n  @#{name}\nend"
            doc = "Returns the value of attribute +#{name}+"
          end
          obj.attach_source(src)
          obj.attach_full_source(full_src)
          obj.attach_docstring(doc)
        end
      end
    end
  end
end
