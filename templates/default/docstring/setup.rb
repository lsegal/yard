def init
  return if object.docstring.blank?
  sections :index, [:deprecated, :text], T('tags')
end

def deprecated
  return unless object.has_tag?(:deprecated)
  erb(:deprecated)
end
