before_section :deprecated, :is_deprecated?

def init
  options.docstring ||= object.docstring
  sections :deprecated, :text, '../tags'
end

protected

def is_deprecated?
  docstring.has_tag?(:deprecated)
end
