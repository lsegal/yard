def init
  sections :index, [:example, :overload, [T('docstring')], :yields, :param, :option, 
    :return, :yieldparam, :yieldreturn, :raises, :see, :author, :since, :version]
end

def param
  tag :param
end

def yields
  tag :yield, :no_names => true, :no_types => true
end

def yieldparam
  tag :yieldparam
end

def yieldreturn
  tag :yieldreturn, :no_names => true
end

def return
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
  erb('tag')
end
