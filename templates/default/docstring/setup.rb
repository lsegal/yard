def init
  return if object.docstring.blank?
  sections :index, [:deprecated, :abstract, :text], T('tags')
end

def abstract
  return unless object.has_tag?(:abstract)
  erb(:abstract)
end

def deprecated
  return unless object.has_tag?(:deprecated)
  erb(:deprecated)
end
