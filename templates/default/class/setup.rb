include T('default/module')

def init
  super
  sections.delete(:children)
  sections.place([:constructor_details, [T('method_details')]]).before(:methodmissing)
end

def constructor_details
  ctors = object.meths(:inherited => true, :included => true)
  return unless @ctor = ctors.find {|o| o.name == :initialize }
  erb(:constructor_details)
end
