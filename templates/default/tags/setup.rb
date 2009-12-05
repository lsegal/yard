def init
  sections :index, [:example, :overload, [T('docstring')], :param, :option, :yields, 
    :yieldparam, :yieldreturn, :return, :raises, :see, :author, :since, :version]
end

def param
  tag :param
end

def yields
  tag :yield, :no_names => true
end

def yieldparam
  tag :yieldparam
end

def yieldreturn
  tag :yieldreturn, :no_names => true
end

def return
  if object.type == :method
    return if object.name == :initialize && object.scope == :instance
    return if object.tags(:return).size == 1 && object.tag(:return).types == ['void']
  end
  tag :return, :no_names => true
end

def raises
  tag :raise, :no_names => true
end

def author
  tag :author, :no_types => true, :no_names => true
end

def since
  tag :since, :no_types => true, :no_names => true
end

def version
  tag :version, :no_types => true, :no_names => true
end

def tag(name, opts = {})
  return unless object.has_tag?(name)
  @no_names = true if opts[:no_names]
  @no_types = true if opts[:no_types]
  @name = name
  out = erb('tag')
  @no_names, @no_types = nil, nil
  out
end
