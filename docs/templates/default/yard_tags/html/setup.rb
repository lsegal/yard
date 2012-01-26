def init
  sections :list, [T('docstring')]
end

def tag_signature(tag)
  types = tag.types || []
  signature = "<strong>@#{tag.name}</strong> "
  case types.first
  when 'with_name'
    signature += "name description"
  when 'with_types'
    signature += "[Types] description"
  when 'with_types_and_name'
    signature += "name [Types] description"
  else
    signature += "description"
  end
  signature
end