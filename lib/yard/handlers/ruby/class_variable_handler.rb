class YARD::Handlers::Ruby::ClassVariableHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles :assign
  
  def process
    if statement[0].type == :var_field && statement[0][0].type == :cvar
      name = statement[0][0][0]
      register ClassVariableObject.new(namespace, name) {|o| o.source = statement }
    end
  end
end