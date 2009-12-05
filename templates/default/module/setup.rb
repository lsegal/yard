include Helpers::ModuleHelper

def init
  sections :header, :box_info, :pre_docstring, T('docstring'), :children, 
    :constant_summary, :inherited_constants, 
    :attribute_summary, [:item_summary], 
    :method_summary, [:item_summary], :inherited_methods,
    :methodmissing, [T('method_details')],
    :attribute_details, [T('method_details')], 
    :method_details_list, [T('method_details')]
end

def pre_docstring
  return if object.docstring.blank?
  erb(:pre_docstring)
end

def children
  @inner = [[:modules, []], [:classes, []]]
  object.children.each do |child|
    @inner[0][1] << child if child.type == :module
    @inner[1][1] << child if child.type == :class
  end
  @inner.map! {|v| [v[0], run_verifier(v[1].sort_by {|o| o.name.to_s })] }
  return if (@inner[0][1].size + @inner[1][1].size) == 0
  erb(:children)
end

def methodmissing
  mms = object.meths(:inherited => true, :included => true)
  return unless @mm = mms.find {|o| o.name == :method_missing && o.scope == :instance }
  erb(:methodmissing)
end

def method_listing(include_specials = true)
  return @smeths ||= method_listing.reject {|o| special_method?(o) } unless include_specials
  return @meths if @meths
  @meths = object.meths(:inherited => false, :included => false)
  @meths = sort_listing(prune_method_listing(@meths))
  @meths
end

def special_method?(meth)
  return true if meth.name(true) == '#method_missing'
  return true if meth.constructor?
  false
end

def attr_listing
  return @attrs if @attrs
  @attrs = []
  [:class, :instance].each do |scope|
    object.attributes[scope].each do |name, rw|
      @attrs << (rw[:read] || rw[:write])
    end
  end
  @attrs = sort_listing(prune_method_listing(@attrs, false))
end

def constant_listing
  return @constants if @constants
  @constants = object.constants(:included => false, :inherited => false)
  @constants += object.cvars
  @constants = run_verifier(@constants)
  @constants
end

def sort_listing(list)
  list.sort_by {|o| [o.scope.to_s, o.name.to_s.downcase] }
end

def docstring_summary(obj)
  docstring = ""
  if obj.tags(:overload).size == 1 && obj.docstring.empty?
    docstring = obj.tag(:overload).docstring
  else
    docstring = obj.docstring
  end

  if docstring.summary.empty? && obj.tags(:return).size == 1 && obj.tag(:return).text
    docstring = Docstring.new(obj.tag(:return).text.gsub(/\A([a-z])/) {|x| x.upcase }.strip)
  end

  docstring.summary
end

def scopes(list)
  [:class, :instance].each do |scope|
    items = list.select {|m| m.scope == scope }
    yield(items, scope) unless items.empty?
  end
end
