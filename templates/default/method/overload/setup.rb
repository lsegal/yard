def init
  sections :header, [:title, [:signature], :docstring]
end

def header
  out = ''
  object.tags(:overload).each do |tag|
    out << render('header', :tag => tag)
  end
  out
end

def signature
  render('signature', :object => tag)
end

def docstring
  T('../../docstring', :docstring => tag.docstring).run
end