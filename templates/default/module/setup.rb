def init
  super
  sections :header, [:title, :files, :mixins, :docstring, :method_summary, :method_details]
end

def mixins
  out = ''
  [:class, :instance].each do |scope|
    out << render(:mixins, :scope => scope) if object.mixins(scope).size > 0
  end
  out
end