include T('default/module')

def init
  super
  sections.place(:subclasses).before(:children)
  sections.delete(:children)
  sections.place([:constructor_details, [T('method_details')]]).before(:methodmissing)
end

def constructor_details
  ctors = object.meths(:inherited => true, :included => true)
  return unless @ctor = ctors.find {|o| o.name == :initialize }
  erb(:constructor_details)
end

def subclasses
  return if object.path == "Object" # don't show subclasses for Object
  if !defined? @@subclasses
    @@subclasses = {}
    list = run_verifier Registry.all(:class)
    list.each do |o| 
      (@@subclasses[o.superclass.path] ||= []) << o if o.superclass
    end
  end
  
  @subclasses = @@subclasses[object.path]
  return if @subclasses.nil? || @subclasses.empty?
  @subclasses = @subclasses.sort_by {|o| o.path }.map do |child|
    name = child.path
    if object.namespace
      name = object.relative_path(child)
    end
    [name, child]
  end
  erb(:subclasses)
end