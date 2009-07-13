inherits '../object'

include YARD::Generators::Helpers::MethodHelper

before_section :aliases, :has_aliases?

def init
  super
  sections[1].unshift :title, [:signature, :aliases]
  sections[1].push :source
end

def has_aliases?
  !object.aliases.empty?
end