# This is a YARD-specific handler for handler DSL syntax. It handles the 
# "process do ... end" syntax and translates it into a "def process; end"
# method declaration.
# 
# @since 0.5.4
class YARD::Handlers::Ruby::ProcessHandler < YARD::Handlers::Ruby::Base
  handles method_call(:process)
  namespace_only
  
  process do
    return unless namespace.is_a?(ClassObject) && namespace.superclass.to_s =~ /^YARD::Handlers/
    register MethodObject.new(namespace, :process) do |o|
      o.docstring = "Main processing callback"
      o.signature = "def process"
      o.parameters = []
    end
  end
end
