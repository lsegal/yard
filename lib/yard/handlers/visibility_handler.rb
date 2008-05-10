class YARD::Handlers::VisibilityHandler < YARD::Handlers::Base
  handles /\A(protected|private|public)\Z/
  
  def process
    self.visibility = statement.tokens.to_s.to_sym
  end
end