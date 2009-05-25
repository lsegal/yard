class YARD::Handlers::Ruby::MethodConditionHandler < YARD::Handlers::Ruby::Base
  handles :if_mod, :unless_mod
  
  def process
    parse_block(statement.then_block, owner: owner)
  end
end