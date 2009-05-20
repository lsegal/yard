class YARD::Handlers::Ruby::VisibilityHandler < YARD::Handlers::Ruby::Base
  handles method_call(:private)
  handles method_call(:protected)
  handles method_call(:public)
  
  def process
    return if (ident = statement.jump(:ident)) == statement
    case statement.type
    when :var_ref
      self.visibility = ident.first
    when :fcall, :command
      statement[1].traverse do |node|
        next unless node.type == :ident || node.type == :string_content
        MethodObject.new(namespace, node.source, scope) {|o| o.visibility = ident.first }
      end
    end
  end
end