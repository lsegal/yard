include YARD::Generators::Helpers::MethodHelper

def init
  sections :header, [:summary]
end

protected

def sorted_method_list
  meths = object.meths(:scope => [:class, :instance]).reject do |o| 
    o.scope == :instance && [:initialize, :method_missing].include?(o.name)
  end
  meths.sort_by {|o| [o.scope, o.visibility, o.name].map {|e| e.to_s } }
end