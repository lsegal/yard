class YARD::Handlers::Ruby::Legacy::ConstantHandler < YARD::Handlers::Ruby::Legacy::Base
  HANDLER_MATCH = /\A[A-Z]\w*\s*=[^=]\s*/m
  handles HANDLER_MATCH
  
  def process
    # Don't document CONSTANTS if they're set in second class objects (methods) because
    # they're not "static" when executed from a method
    return unless owner.is_a? NamespaceObject
    
    name, value = *statement.tokens.to_s.split(/\s*=\s*/, 2)
    if value =~ /\A\s*Struct.new(?:\s*\(?|\b)/
      process_structclass(name, $')
    else
      register ConstantObject.new(namespace, name) {|o| o.source = statement; o.value = value.strip }
    end
  end
  
  private
  
  def process_structclass(classname, parameters)
    scope = :instance
    klass = register ClassObject.new(namespace, classname)
    klass.superclass = P(:Struct)

    tokval_list(YARD::Parser::Ruby::Legacy::TokenList.new(parameters), TkSYMBOL).each do |name|
      klass.attributes[scope][name] = SymbolHash[:read => nil, :write => nil]
      {:read => name, :write => "#{name}="}.each do |type, meth|
        klass.attributes[scope][name][type] = MethodObject.new(klass, meth, scope)
      end
    end
  end
end