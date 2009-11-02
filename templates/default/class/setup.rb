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
  if !defined? @@subclasses
    @@subclasses = {}
    list = run_verifier Registry.all(:class)
    list.each do |o| 
      (@@subclasses[o.superclass] ||= []) << o if o.superclass
    end
  end
  
  @subclasses = @@subclasses[object]
  return if @subclasses.nil? || @subclasses.empty?
  erb(:subclasses)
end