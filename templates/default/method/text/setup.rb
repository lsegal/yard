def init
  sections :header, [:method_signature, T('docstring')]
end

def format_object_title(object)
  title = "Method: #{object.name(true)}"
  title += " (#{object.namespace})" if object.namespace != Registry.root
  title
end
