def init
  objects = options[:objects]
  files = options[:files]
  
  generate_assets
  serialize('index.html')
  files.each {|file| serialize_file(file) }

  options.delete(:objects)
  options.delete(:files)
  objects.each do |object|
    next if options[:verifier] && options[:verifier].call(object).is_a?(FalseClass)
    serialize(object)
  end
end

def serialize(object)
  options[:object] = object
  Templates::Engine.with_serializer(object, options[:serializer]) { T('../layout').run(options) }
end

def serialize_file(file)
  options[:object] = Registry.root
  options[:file] = file
  Templates::Engine.with_serializer(File.basename(file) + '.html', 
    options[:serializer]) { T('../layout').run(options) }
  options.delete(:file)
end

def asset(path, content)
  options[:serializer].serialize(path, content) if options[:serializer]
end

def generate_assets
  %w( js/jquery.js js/autocomplete.js js/app.js css/style.css ).each do |file|
    asset(file, file(file))
  end
  
  asset('objects.json', Registry.all.sort_by {|o| o.path ? o.path.to_s : '' }.join("\n"))
end