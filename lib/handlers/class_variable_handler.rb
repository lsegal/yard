class YARD::ClassVariableHandler < YARD::CodeObjectHandler
  HANDLER_MATCH = /\A@@\S*\s*=\s*/m
  handles HANDLER_MATCH
  
  def process
    return unless object.is_a? YARD::CodeObjectWithMethods
    cvar, expr = *statement.tokens.to_s.gsub(/\r?\n/, '').split(/\s*=\s*/, 2)
    object[:class_variables].update(cvar => expr)
  end
end