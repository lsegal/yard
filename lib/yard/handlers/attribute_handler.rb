class YARD::Handlers::AttributeHandler < YARD::Handlers::Base
  handles /\Aattr(?:_(?:reader|writer|accessor))?(?:\s|\()/
  
  def process
    begin
      attr_type   = statement.tokens.first.text.to_sym
      symbols     = eval("[" + statement.tokens[1..-1].to_s + "]")
      read, write = true, false
    rescue SyntaxError
      YARD.logger.warning "in AttributeHandler: Undocumentable attribute statement: '#{statement.tokens.to_s}'\n" +
                     "\tin file '#{parser.file}':#{statement.tokens.first.line_no}"
      return
    end
    
    # Change read/write based on attr_reader/writer/accessor
    case attr_type
    when :attr
      # In the case of 'attr', the second parameter (if given) isn't a symbol.
      write = symbols.pop if symbols.size == 2
    when :attr_accessor
      write = true
    when :attr_reader
      # change nothing
    when :attr_writer
      read, write = false, true
    end

    # Add all attributes
    symbols.each do |name| 
      # Show their methods as well
      [name, "#{name}="].each do |meth|
        next unless (meth.to_s.include?("=") ? write : read)
        
        MethodObject.new(namespace, meth, scope) do |o|
          if meth.to_s.include? "="
            src = "def #{meth}(value)"
            full_src = "#{src}\n  @#{name} = value\nend"
            doc = "Sets the attribute +#{name}+\n@param value the value to set the attribute +#{name}+ to."
          else
            src = "def #{meth}"
            full_src = "#{src}\n  @#{name}\nend"
            doc = "Returns the value of attribute +#{name}+"
          end
          o.source = full_src
          o.docstring = statement.comments.to_s.empty? ? doc : statement.comments
          o.file = parser.file
          o.line = statement.tokens.first.line_no
        end
      end

      namespace.attributes.update name => { :read => read, :write => write }
    end
  end
end