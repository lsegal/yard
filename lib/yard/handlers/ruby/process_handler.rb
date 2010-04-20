class YARD::Handlers::Ruby::ProcessHandler < YARD::Handlers::Ruby::Base
  handles method_call(:process)
  namespace_only
  
  process do
    return unless namespace.is_a?(ClassObject) && namespace.superclass.to_s =~ /^YARD::Handlers/
    register MethodObject.new(namespace, :process) do |o| 
      o.signature = "def process"
      o.parameters = []
    end
  end
end
