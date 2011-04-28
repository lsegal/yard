# Handles a macro (dsl-style method)
class YARD::Handlers::Ruby::MacroHandler < YARD::Handlers::Ruby::Base
  handles method_call
  namespace_only
  
  process do
    if statement.call? && statement.method_name(true).to_s =~ /\Aattr_(reader|writer|accessor)\Z/
      return # Ignore attr_*
    end

    @orig_docstring = @docstring = YARD::Docstring.new(statement.comments)
    parse_comments
    return if !@macro && @docstring.tags.size == 0
    @docstring.hash_flag = statement.comments_hash_flag
    @docstring.line_range = statement.comments_range
    name = method_name
    raise UndocumentableError, "method, missing name" if name.nil? || name.empty?
    tmp_scope = sanitize_scope
    tmp_vis = sanitize_visibility
    object = YARD::CodeObjects::MethodObject.new(namespace, name, tmp_scope)
    register(object)
    object.visibility = tmp_vis
    object.dynamic = true
    object.docstring = @docstring
    object.signature = method_signature
    create_attribute_data(object)
    create_macro
  end
  
  private
  
  MACRO_MATCH = /(\\)?\$(?:\{(-?\d+|\*)(?:-(-?\d+)?)?\}|(-?\d+|\*))/
  
  def create_macro
    return unless new_macro?
    macro_name = @orig_docstring.tag(:macro).name
    raise UndocumentableError, 'method/attribute, missing macro name' unless macro_name
    macro_object = MacroObject.new(:root, macro_name)
    macro_object.raw_data = macro_data(true)
    macro_object.object = namespace
    macro_object.method_name = caller_method.to_s
    macro_object.attached = attach_macro?
  end
  
  def try_to_reuse_macro
    return if new_macro?
    
    if @docstring.tag(:macro)
      if @macro = Registry.at(".macro.#{@docstring.tag(:macro).name}")
        return @macro
      end
    end
    
    # Look for implicit macros
    Registry.all(:macro).each do |macro|
      next unless macro.attached
      next unless macro.method_name == caller_method
      namespace.inheritance_tree.each do |obj|
        ensure_loaded!(obj)
        return(@macro = macro) if obj == macro.object
      end
    end
    @macro = nil
  end
  
  def parse_comments
    try_to_reuse_macro
    comments = ''
    comments += "\n" + @macro.raw_data if @macro
    if new_macro?
      comments += "\n" + macro_data
    else
      comments += "\n" + @docstring.all if @docstring.all
    end
    comments = parse_macro_comments(comments) if new_macro? || @macro
    @docstring = Docstring.new(comments)
    comments
  end
  
  def caller_method
    if statement.call?
      statement.method_name(true).to_s
    else
      statement[0].jump(:ident).source
    end
  end
  
  def create_attribute_data(object)
    return unless object.docstring.tag(:attribute)
    ensure_loaded!(namespace)
    clean_name = object.name.to_s.sub(/=$/, '')
    namespace.attributes[object.scope][clean_name] ||= SymbolHash[:read => nil, :write => nil]
    if attribute_readable?
      namespace.attributes[object.scope][clean_name][:read] = object
    end
    if attribute_writable?
      if object.name.to_s[-1,1] == '='
        writer = object
      else
        writer = MethodObject.new(namespace, object.name.to_s + '=', object.scope)
        register(writer)
        writer.signature = "def #{object.name}=(value)"
        writer.visibility = object.visibility
        writer.dynamic = true
      end
      namespace.attributes[object.scope][clean_name][:write] = writer
    end
  end
  
  def parse_macro_comments(comments)
    comments.gsub(MACRO_MATCH) do
      escape, first, last, rng = $1, $2 || $4, $3, $4 ? false : true
      next $&[1..-1] if escape
      next $& if (first == '0' || first == '*') && last
      if first == '*'
        statement.source
      elsif first == '0'
        statement.method_name(true)
      else
        first_i = first.to_i
        last_i = (last ? last.to_i : statement.parameters(false).size)
        last_i = first_i unless rng
        first_i -= 1 if first_i > 0
        last_i -= 1 if last_i > 0
        statement.parameters[first_i..last_i].map do |x|
          x.jump(:ident, :tstring_content).source
        end.join(", ")
      end
    end
  end
  
  def new_macro?
    if @orig_docstring.tag(:macro) 
      if types = @orig_docstring.tag(:macro).types
        return true if types.include?('new') || types.include?('attach')
      end
      if @orig_docstring.all =~ MACRO_MATCH
        return true
      end
    end
    false
  end
  
  def macro_data(tag_only = false)
    docstring = @orig_docstring.dup
    docstring.delete_tags(:macro)
    tag_text = @orig_docstring.tag(:macro).text
    if !tag_text || tag_text.strip.empty?
      docstring.to_raw
    elsif tag_only
      tag_text
    else
      [tag_text, docstring.to_raw].join("\n")
    end
  end
  
  def attach_macro?
    if @orig_docstring.tag(:macro) && types = @orig_docstring.tag(:macro).types
      return true if types.include?('attach')
    end
    false
  end
  
  def attribute_writable?
    if @docstring.tag(:attribute) 
      types = @docstring.tag(:attribute).types
      return types ? types.join.include?('w') : true
    end
    false
  end
  
  def attribute_readable?
    if @docstring.tag(:attribute) 
      types = @docstring.tag(:attribute).types
      return types ? (types.join =~ /(?<!w)r/ ? true : false) : true
    end
    false
  end

  def method_name
    name = nil
    [:method, :attribute, :overload].each do |tag|
      if @docstring.tag(tag)
        name = @docstring.tag(tag).text
        break
      end
    end
    name = nil if name =~ /\A\s*\Z/
    name ||= call_first_parameter
    return unless name
    if name =~ /\A\s*([^\(; \t]+)/
      name = $1
    end
    if @docstring.tag(:attribute) && !attribute_readable?
      name = name + '='
    end
    name
  end
  
  def method_signature
    if @docstring.tag(:method)
      name = @docstring.tag(:method).text
    elsif @docstring.tag(:overload)
      name = @docstring.tag(:overload).text
    elsif @docstring.tag(:attribute)
      name = @docstring.tag(:attribute).text
      name += '=(value)' if !attribute_readable?
    else
      name = method_name
    end
    name = nil if name =~ /\A\s*\Z/
    name ||= call_first_parameter
    name =~ /^def\b/ ? name : "def #{name}"
  end
  
  def call_first_parameter
    return nil unless statement.call?
    statement.parameters[0].jump(:ident, :tstring_content).source
  end
  
  def sanitize_scope
    tmp_scope = @docstring.tag(:scope) ? @docstring.tag(:scope).text : ''
    %w(class instance).include?(tmp_scope) ? tmp_scope.to_sym : scope
  end
  
  def sanitize_visibility
    vis = @docstring.tag(:visibility) ? @docstring.tag(:visibility).text : ''
    %w(public protected private).include?(vis) ? vis.to_sym : visibility
  end
end
