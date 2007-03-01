class YARD::ConstantHandler < YARD::CodeObjectHandler
  HANDLER_MATCH = /\A[^@\$]\S*\s*=\s*/m
  handles HANDLER_MATCH
  
  def process
    return unless object.is_a? YARD::CodeObjectWithMethods
    const, expr = *statement.tokens.to_s.split(/\s*=\s*/, 2)
    #expr.gsub!(/\/s+/,' ')
    obj = YARD::ConstantObject.new(const, object, statement)
  end
end