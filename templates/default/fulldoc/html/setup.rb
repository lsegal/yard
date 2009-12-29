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
  generate_frameset
end

def generate_method_list
  @items = prune_method_listing(Registry.all(:method), false)
  @items = @items.reject {|m| m.name.to_s =~ /=$/ && m.is_attribute? }
  @items = @items.sort_by {|m| m.name.to_s }
  @list_title = "Method List"
  @list_type = "methods"
  asset('method_list.html', erb(:full_list))
end

def generate_class_list
  @list_title = "Class List"
  @list_type = "class"
  asset('class_list.html', erb(:full_list))
end

def generate_file_list
  @file_list = true
  @items = options[:files]
  @list_title = "File List"
  @list_type = "files"
  asset('file_list.html', erb(:full_list))
  @file_list = nil
end

def generate_frameset
  asset('frames.html', erb(:frames))
end

def class_list(root = Registry.root)
  out = ""
  children = run_verifier(root.children)
  if root == Registry.root
    children += Registry.all(:class, :module).select {|o| o.namespace.is_a?(CodeObjects::Proxy) }
  end
  children.sort_by {|child| child.path }.map do |child|
    if child.is_a?(CodeObjects::NamespaceObject)
      name = child.namespace.is_a?(CodeObjects::Proxy) ? child.path : child.name
      has_children = child.children.any? {|o| o.is_a?(CodeObjects::NamespaceObject) }
      out << "<li>"
      out << "<a class='toggle'></a> " if has_children
      out << linkify(child, name)
      out << " &lt; #{child.superclass.name}" if child.is_a?(CodeObjects::ClassObject) && child.superclass
      out << "<small class='search_info'>"
      if !child.namespace || child.namespace.root?
        out << "Top Level Namespace"
      else
        out << child.namespace.path
      end
      out << "</small>"
      out << "</li>"
      out << "<ul>#{class_list(child)}</ul>" if has_children
    end
  end
  out
end