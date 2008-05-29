class YARD::Handlers::VisibilityHandler < YARD::Handlers::Base
  handles /\A(protected|private|public)/
  
  def process
    if statement.tokens.size == 1
      self.visibility = statement.tokens.to_s.to_sym
    else
      last_tk = nil
      vis = statement.tokens.first.text
      statement.tokens[2..-1].each do |tk|
        name = nil
        if tk.is_a?(TkSTRING)
          name = eval(tk.text)
        elsif (tk.is_a?(TkIDENTIFIER) || tk.is_a?(TkFID)) && last_tk.is_a?(TkSYMBEG)
          name = eval(":" + tk.text)
        end
        
        if name
          MethodObject.new(namespace, name, scope) do |o|
            o.visibility = vis
            o.dynamic = true if owner != namespace
          end
        end
        
        last_tk = tk
      end
    end
  end
end