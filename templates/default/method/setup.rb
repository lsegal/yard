inherits '../object'

include YARD::Generators::Helpers::MethodHelper

before_section :aliases, :has_aliases?
before_section :overload, :has_overloads?

def init
  super
  sections[1].unshift :title, [:signature, :aliases]
  sections[1].push :overload, :source
end

protected

def has_aliases?
  !object.aliases.empty?
end

def has_overloads?
  object.tags(:overload).size > 1
end