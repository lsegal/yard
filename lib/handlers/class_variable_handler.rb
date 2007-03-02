class YARD::ClassVariableHandler < YARD::CodeObjectHandler
  HANDLER_MATCH = /\A@@\S*\s*=\s*/m
  handles HANDLER_MATCH
  
  def process
    return unless object.is_a? YARD::CodeObjectWithMethods
    YARD::ClassVariableObject.new(statement, object)
  end
end