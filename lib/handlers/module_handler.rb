class YARD::ModuleHandler < YARD::CodeObjectHandler
  handles RubyToken::TkMODULE
  
  def process
    module_name = move_to_namespace(statement.tokens[2].text)
    child = YARD::ModuleObject.new(module_name, object, statement.comments)
    enter_namespace(child) { parse_block }
  end
end
