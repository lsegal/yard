include YARD::Generators::Helpers::MethodHelper

before_section :aliases, :has_aliases?
before_section :overload, :has_overloads?

def init
  super
  sections :header, [:title, [:signature, :aliases], :docstring, :overload, :source]
end

protected

def has_aliases?
  !object.aliases.empty?
end

def has_overloads?
  object.tags(:overload).size > 1
end
