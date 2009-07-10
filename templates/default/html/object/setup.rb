before_section :deprecated, :is_deprecated?

def init
  sections :deprecated, :docstring, :tags, :overload, :source
end

def is_deprecated?
  object.has_tag?(:deprecated)
end