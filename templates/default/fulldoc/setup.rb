def init
  objects = options[:objects]
  options[:files] = ([options[:readme]] + options[:files]).compact.map {|t| t.to_s }
  options[:readme] = options[:files].first
  
  generate_assets
  serialize('glossary.html')
  options[:files].each {|file| serialize_file(file) }

  options.delete(:objects)
  options.delete(:files)
  objects.each do |object|
    next if options[:verifier] && options[:verifier].call(object).is_a?(FalseClass)
    serialize(object)
  end
end

def serialize(object)
  options[:object] = object
  Templates::Engine.with_serializer(object, options[:serializer]) do
    T('../layout').run(options)
  end
end

def serialize_file(file)
  options[:object] = Registry.root
  options[:file] = file
  if file == options[:readme]
    options[:serialized_path] = 'index.html'
  else
    options[:serialized_path] = 'file.' + File.basename(file.gsub(/\..+$/, '')) + '.html'
  end
  
  Templates::Engine.with_serializer(options[:serialized_path], options[:serializer]) do
    T('../layout').run(options)
  end
  options.delete(:file)
  options.delete(:serialized_path)
end

def asset(path, content)
  options[:serializer].serialize(path, content) if options[:serializer]
end

def generate_assets
  %w( js/jquery.js js/app.js js/full_list.js 
      css/style.css css/full_list.css css/common.css ).each do |file|
    asset(file, file(file))
  end
  
  @object = Registry.root
  generate_method_list
  generate_class_list
  generate_file_list
end

def generate_method_list
  @items = run_verifier(Registry.all(:method)).sort_by {|m| m.name.to_s }
  @list_title = "Method List"
  asset('method_list.html', erb(:full_list))
end

def generate_class_list
  @items = [Registry.root] + options[:objects].reject {|o| o.type == :root }.sort_by {|m| m.name.to_s }
  @list_title = "Namespace List"
  asset('class_list.html', erb(:full_list))
end

def generate_file_list
  @file_list = true
  @items = options[:files]
  @list_title = "File List"
  asset('file_list.html', erb(:full_list))
  @file_list = nil
end