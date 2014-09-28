def init
  sections :layout, [:diskfile]
end

def diskfile
  resolve_links(@file.contents)
end
