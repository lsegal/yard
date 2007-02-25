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
      object[:attributes].update(name => { :read => read, :write => write })

      # Show their methods as well
      [name, "#{name}="].each do |method|
        YARD::MethodObject.new(method, current_visibility, current_scope, object, statement.comments)
      end
    end
  end
end
