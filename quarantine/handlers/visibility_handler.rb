class YARD::VisibilityHandler < YARD::CodeObjectHandler
  handles /\A(protected|private|public)\Z/
  
  def process
    self.current_visibility = statement.tokens.to_s.to_sym
  end
end