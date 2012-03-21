def init
  sections :list, [T('docstring')]
end

def tag_signature(tag)
  types = tag.types || []
  prefix = tag.tag_name == 'yard.directive' ? '@!' : '@'
  signature = "<strong>#{prefix}#{tag.name}</strong> "
  case types.first
  when 'with_name'
    signature += "name description"
  when 'with_types'
    signature += "[Types] description"
  when 'with_types_and_name'
    signature += "name [Types] description"
  when 'with_title_and_text'
    signature += "title | description"
  when 'with_types_and_title'
    signature += "[Types] title | description"
  else
    signature += "description"
  end
  signature
end