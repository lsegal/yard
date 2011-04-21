# (see Ruby::ProcessHandler)
class YARD::Handlers::Ruby::Legacy::ProcessHandler < YARD::Handlers::Ruby::Legacy::Base
  handles /\Aprocess(?:\(?|\s)/
  namespace_only

  process do
    return unless namespace.is_a?(ClassObject) && namespace.superclass.to_s =~ /^YARD::Handlers/
    register MethodObject.new(namespace, :process) do |o|
      o.signature = "def process"
      o.parameters = []
    end
  end
end
