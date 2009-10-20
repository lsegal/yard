include T('default/module/text')

def format_object_title(object)
  "Class: #{object.path} < #{object.superclass.path}"
end