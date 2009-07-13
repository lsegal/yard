before_section :header, :has_tags?
before_section :option, :has_options?
before_section :param, :has_params?
before_section :todo, :has_todo?
before_section :see, :has_see?
before_section :example, :has_example?

def init
  sections :header, [:example, :param, :yield_tag, :yieldparam, :yieldreturn, 
    :return, :raise_tag, :todo, :author, :version, :since, :see]
    
  if docstring.tags(:overload).size == 1
    size = sections.last.size
    sections.last.reverse.each_with_index do |item, index|
      sections.last[size - index - 1, 1] = [:with_overload, [item]]
    end
  end
end

def with_overload
  yieldall(:tag_object => docstring.tag(:overload)) + yieldall(:tag_object => object)
end

def yield_tag
  render_tags :yield
end

def yieldparam
  render_tags :yieldparam
end

def yieldreturn
  render_tags :yieldreturn
end

def return
  render_tags :return
end

def raise_tag
  render_tags :raise, :no_names => true
end

def author
  render_tags :author, :no_types => true, :no_names => true
end

def version
  render_tags :version, :no_types => true, :no_names => true
end

def since
  render_tags :since, :no_types => true, :no_names => true
end

private

def render_tags(name, opts = {})
  return "" unless docstring.has_tag?(name)
  opts = { :name => name }.update(opts)
  render('_tags', opts)
end

def has_todo?
  docstring.has_tag?(:todo)
end

def has_see?
  docstring.has_tag?(:see)
end

def has_tags?
  docstring.tags.size > 0
end

def has_params?
  options.tag_object ||= options.tag || docstring.object
  tag_object.respond_to?(:parameters) && tags_by_param.size > 0
end

def has_options?
  docstring.has_tag?(:option)
end

def has_example?
  docstring.has_tag?(:example)
end

def tags_by_param
  cache = {}
  [:param, :option].each do |sym|
    tag_object.tags(sym).each do |t|
      cache[t.name.to_s] = t
    end
  end
  
  tag_object.parameters.map do |p|
    name = p.first.to_s
    cache[name] || cache[name[/^[*&](\w+)$/, 1]]
  end.compact
end