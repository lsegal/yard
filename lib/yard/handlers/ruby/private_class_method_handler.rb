# Sets visibility of a class method
class YARD::Handlers::Ruby::PrivateClassMethodHandler < YARD::Handlers::Ruby::Base
  handles method_call(:private_class_method)
  namespace_only

  process do
    errors = []
    statement.parameters.each do |param|
      next unless AstNode === param
      begin
        privatize_class_method(param)
      rescue UndocumentableError => err
        errors << err.message
      end
    end
    if errors.size > 0
      msg = errors.size == 1 ? ": #{errors[0]}" : "s: #{errors.join(", ")}"
      raise UndocumentableError, "private class_method#{msg} for #{namespace.path}"
    end
  end

  private

  def privatize_class_method(node)
    if node.literal?
      method = Proxy.new(namespace, node[0][0][0], :method)
      ensure_loaded!(method)
      method.visibility = :private
    else
      raise UndocumentableError, "invalid argument to private_class_method: #{node.source}"
    end
  rescue NamespaceMissingError
    raise UndocumentableError, "private visibility set on unrecognized method: #{node[0]}"
  end
end