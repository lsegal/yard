class YARD::Handlers::Ruby::ConstantHandler < YARD::Handlers::Ruby::Base
  namespace_only
  handles :assign
  
  def process
    if statement[1].call? && statement[1][0][0] == s(:const, "Struct") && 
        statement[1][2] == s(:ident, "new")
      process_structclass(statement)
    elsif statement[0].type == :var_field && statement[0][0].type == :const
      process_constant(statement)
    end
  end
  
  private
  
  def process_constant(statement)
    name = statement[0][0][0]
    value = statement[1].source
    register ConstantObject.new(namespace, name) {|o| o.source = statement; o.value = value.strip }
  end
  
  def process_structclass(statement)
    lhs = statement[0][0]
    if lhs.type == :const
      klass = register ClassObject.new(namespace, lhs[0])
      klass.superclass = P(:Struct)
      parse_attributes(klass, statement[1].parameters)
    else
      raise YARD::Parser::UndocumentableError, "Struct assignment to #{statement[0].source}"
    end
  end
  
  def parse_attributes(klass, attributes)
    return unless attributes
    
    scope = :instance
    attributes.each do |node|
      next if !node.respond_to?(:type) || node.type != :symbol_literal
      name = node.jump(:ident).source
      klass.attributes[scope][name] = SymbolHash[:read => nil, :write => nil]
      {read: name, write: "#{name}="}.each do |type, meth|
        klass.attributes[scope][name][type] = MethodObject.new(klass, meth, scope)
      end
    end
  end
end