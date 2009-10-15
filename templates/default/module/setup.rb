def init
  sections :header, :box_info, :pre_docstring, T('../docstring'), :children, 
    :constant_summary, :attribute_summary, :method_summary, :inherited_methods,
    :attribute_details, [T('../method_details')], 
    :methodmissing, [T('../method_details')],
    :method_details_list, [T('../method_details')]
end

def pre_docstring
  return if object.docstring.blank?
  erb(:pre_docstring)
end

def children
  @inner = {:modules => [], :classes => []}
  object.children.each do |child|
    @inner[:modules] << child if child.type == :module
    @inner[:classes] << child if child.type == :class
  end
  return if (@inner[:modules].size + @inner[:classes].size) == 0
  erb(:children)
end

def methodmissing
  mms = object.meths(:inherited => true, :included => true)
  return unless @mm = mms.find {|o| o.name == :method_missing && o.scope == :instance }
  erb(:methodmissing)
end

def method_listing(include_specials = true)
  return @smeths ||= method_listing.reject {|o| special_methods.include? o.name(true).to_s } unless include_specials
  return @meths if @meths
  @meths = object.meths(inherited: false, included: false)
  @meths = prune_listing(@meths)
  @meths.reject!(&:is_attribute?)
  @meths
end

def special_methods
  ["#initialize", "#method_missing"]
end

def attr_listing
  return @attrs if @attrs
  @attrs = []
  [:class, :instance].each do |scope|
    object.attributes[scope].each do |name, rw|
      @attrs << (rw[:read] || rw[:write])
    end
  end
  @attrs = prune_listing(@attrs)
end

def prune_listing(list)
  list = list.reject {|o| options[:verifier].call(o).is_a?(FalseClass) } if options[:verifier]
  list = list.reject {|o| !options[:visibilities].include? o.visibility } if options[:visibilities]
  list = list.reject(&:is_alias?)
  list.sort_by {|o| [o.scope, (options[:visibilities]||[]).index(o.visibility), o.name].join(":") }
end

def constant_listing
  return @constants if @constants
  @constants = object.constants(:included => false, :inherited => false)
  @constants = @constants.reject {|o| options[:verifier].call(o).is_a?(FalseClass) } if options[:verifier]
end
