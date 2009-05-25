class YARD::Handlers::Ruby::ConstantHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles :assign
  
  def process
    if statement[0].type == :var_field && statement[0][0].type == :const
      name = statement[0][0][0]
      value = statement[1].source
      register ConstantObject.new(namespace, name) {|o| o.source = statement; o.value = value.strip }
    end
  end
end