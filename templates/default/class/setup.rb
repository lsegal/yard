inherits '../module'

before_section(:methodmissing) { !method_missing_method.nil? }
before_section(:constructor) { !constructor_method.nil? }

def init
  super
  sections[1].place(:inheritance).before(:mixins)
  sections[1].place([:methodmissing, ['../method'], :constructor, ['../method']]).after(:docstring)
end

protected

def mixins_scope(scope)
  object.mixins(scope).map {|o| linkify o }.join(", ")
end

def method_missing_method
  @method_missing ||= object.meths.find {|o| o.name == :method_missing && o.scope == :instance }
end

def method_missing_method_inherited?
  method_missing_method.namespace != object
end

def constructor_method
  @constructor ||= object.meths.find {|o| o.name == :initialize && o.scope == :instance }
end

def constructor_method_inherited?
  constructor_method.namespace != object
end
