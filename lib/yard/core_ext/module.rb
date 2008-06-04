class Module
  def class_name
    name.split("::").last
  end
  
  def namespace
    name.split("::")[0..-2].join("::")
  end
end