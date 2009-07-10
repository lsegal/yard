inherits '../object'

include YARD::Generators::Helpers::MethodHelper

before_section :aliases, :has_aliases?

def init
  super
  sections :title, [:signature, :aliases], *sections
  sections :header, [*sections]
end

def has_aliases?
  !object.aliases.empty?
end