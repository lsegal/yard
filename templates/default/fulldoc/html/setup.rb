include Helpers::ModuleHelper

def init
  options[:objects] = objects = run_verifier(options[:objects])
  options[:files] = ([options[:readme]] + options[:files]).compact.map {|t| t.to_s }
  options[:readme] = options[:files].first
  options[:title] ||= "Documentation by YARD #{YARD::VERSION}"
  
  generate_assets
  serialize('_index.html')
  options[:files].each_with_index do |file, i| 
    serialize_file(file, i == 0 ? options[:title] : nil) 
  end

  options.delete(:objects)
  options.delete(:files)
  
  objects.each do |object| 
    begin
      serialize(object)
    rescue => e
      path = options[:serializer].serialized_path(object)
      log.error "Exception occurred while generating '#{path}'"
      log.backtrace(e)
    end
  end
end

def serialize(object)
  options[:object] = object
  serialize_index(options) if object == '_index.html' && options[:files].empty?
  Templates::Engine.with_serializer(object, options[:serializer]) do
    T('layout').run(options)
  end
end

def serialize_index(options)
  Templates::Engine.with_serializer('index.html', options[:serializer]) do
    T('layout').run(options)
  end
end

def serialize_file(file, title = nil)
  options[:object] = Registry.root
  options[:file] = file
  options[:page_title] = title
  options[:serialized_path] = 'file.' + File.basename(file.gsub(/\.[^.]+$/, '')) + '.html'

  serialize_index(options) if file == options[:readme]
  Templates::Engine.with_serializer(options[:serialized_path], options[:serializer]) do
    T('layout').run(options)
  end
  options.delete(:file)
  options.delete(:serialized_path)
  options.delete(:page_title)
end

def asset(path, content)
  options[:serializer].serialize(path, content) if options[:serializer]
end

def generate_assets
  %w( js/jquery.js js/app.js js/full_list.js 
      css/style.css css/full_list.css css/common.css ).each do |file|
    asset(file, file(file, true))
  end
  
  @object = Registry.root
  generate_method_list
  generate_class_list
  generate_file_list
end

def generate_method_list
  @items = prune_method_listing(Registry.all(:method), false)
  @items = @items.reject {|m| m.name.to_s =~ /=$/ && m.is_attribute? }
  @items = @items.sort_by {|m| m.name.to_s }
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