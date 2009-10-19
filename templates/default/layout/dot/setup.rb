attr_reader :contents

def init
  if object
    type = object == Registry.root ? :module : object.type
    sections :header, [T("../#{type}")]
  else
    sections :header, [:contents]
  end
end

def header
  tidy erb(:header)
end
