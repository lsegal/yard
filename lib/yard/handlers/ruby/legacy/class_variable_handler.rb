class YARD::Handlers::Ruby::Legacy::ClassVariableHandler < YARD::Handlers::Ruby::Legacy::Base
  HANDLER_MATCH = /\A@@\w+\s*=\s*/m
  handles HANDLER_MATCH
  
  def process
    # Don't document @@cvars if they're set in second class objects (methods) because
    # they're not "static" when executed from a method
    return unless owner.is_a? NamespaceObject
    
    name, value = *statement.tokens.to_s.split(/\s*=\s*/, 2)
    register ClassVariableObject.new(namespace, name) do |o| 
      o.source = statement
      o.value = value.strip
    end
  end
end