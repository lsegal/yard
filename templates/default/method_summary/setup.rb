include YARD::Generators::Helpers::MethodHelper

# @test
def init
  sections :header, [:summary]
end

protected

def sorted_method_list
  meths = object.meths(:scope => [:class, :instance]).reject do |o| 
    o.scope == :instance && [:initialize, :method_missing].include?(o.name)
  end
  meths.sort_by {|o| [o.scope, o.visibility, o.name] }
end