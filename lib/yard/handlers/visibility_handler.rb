class YARD::Handlers::VisibilityHandler < YARD::Handlers::Base
  handles /\A(protected|private|public)/
  
  def process
    vis = statement.tokens.first.text
    if statement.tokens.size == 1
      self.visibility = vis
    else
      tokval_list(statement.tokens[2..-1], :attr).each do |name|
        register MethodObject.new(namespace, name, scope) {|o| o.visibility = vis }
      end
    end
  end
end