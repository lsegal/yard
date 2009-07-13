before_section :deprecated, :is_deprecated?

def init
  sections :deprecated, :text, '../tags'
end

protected

def is_deprecated?
  object.has_tag?(:deprecated)
end
