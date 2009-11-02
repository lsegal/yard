def init
  return if object.docstring.blank?
  sections :index, [:deprecated, :abstract, :todo, :note, :text], T('tags')
end

def abstract
  return unless object.has_tag?(:abstract)
  erb(:abstract)
end

def deprecated
  return unless object.has_tag?(:deprecated)
  erb(:deprecated)
end

def todo
  return unless object.has_tag?(:todo)
  erb(:todo)
end

def note
  return unless object.has_tag?(:note)
  erb(:note)
end

def docstring_text
  text = ""
  if object.tags(:overload).size == 1 && object.docstring.empty?
    text = object.tag(:overload).docstring
  else
    text = object.docstring
  end
  
  if text.strip.empty? && object.tags(:return).size == 1 && object.tag(:return).text
    text = object.tag(:return).text.gsub(/\A([a-z])/) {|x| x.upcase }
  end
  
  text.strip
end