attr_accessor :object

def init
  sections :index, [:overload, :example, :param, :option, :return, :see]
end

def param
  tag :param
end

def return
  tag :return, :no_names => true
end

def tag(name, opts = {})
  return unless object.has_tag?(name)
  @no_names = true if opts[:no_names]
  @no_types = true if opts[:no_types]
  @name = name
  erb('tag')
end
