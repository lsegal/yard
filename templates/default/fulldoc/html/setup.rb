include Helpers::ModuleHelper

def init
  options[:objects] = objects = run_verifier(options[:objects])
  options[:files] = ([options[:readme]] + options[:files]).compact.map {|t| t.to_s }
  options[:readme] = options[:files].first
  options[:title] ||= "Documentation by YARD #{YARD::VERSION}"
  
  options[:stylesheets] = stylesheets
  options[:javascripts] = javascripts
  options[:search_fields] = menu_lists
  
  return serialize_onefile if options[:onefile]
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

#
# The core javascript files for the documentation template
#
def javascripts
  [ 'js/jquery.js', 'js/app.js' ]
end

#
# Javascript files that are additionally loaded for the searchable full lists
# e.g. Class List
#
def javascripts_full_list
  [ 'js/jquery.js', 'js/full_list.js' ]
end

#
# The core stylesheets for the documentation template
#
def stylesheets
  [ 'css/style.css', 'css/common.css' ]
end

#
# Stylesheet files that are additionally loaded for the searchable full lists
# e.g. Class List
#
def stylesheets_full_list
  [ 'css/full_list.css', 'css/common.css' ]
end

def serialize(object)
  options[:object] = object
  serialize_index(options) if object == '_index.html' && options[:files].empty?
  Templates::Engine.with_serializer(object, options[:serializer]) do
    T('layout').run(options)
  end
end

def serialize_onefile
  options[:css_data] = stylesheets.map{|sheet| file(sheet,true) }.join("\n")
  options[:js_data] = javascripts.map{|script| file(script,true) }.join("")
  Templates::Engine.with_serializer('index.html', options[:serializer]) do
    T('onefile').run(options)
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

#
# The list of search links and drop-down menus
#
def menu_lists
  [ { :type => 'class', :title => 'Classes', :search_title => 'Class List' },
    { :type => 'method', :title => 'Methods', :search_title => 'Method List' }, 
    { :type => 'file', :title => 'Files', :search_title => 'File List' } ]
end

def generate_assets
  
  (javascripts + javascripts_full_list + 
  stylesheets + stylesheets_full_list).uniq.each do |file|
    asset(file, file(file, true))
  end
  
  @javascripts = javascripts_full_list
  @stylesheets = stylesheets_full_list
  
  @object = Registry.root
  
  menu_lists.each do |list|
    
    list_generator_method = "generate_#{list[:type]}_list"
    
    if respond_to?(list_generator_method)
      send(list_generator_method)
    else
      log.error "Unable to generate '#{list[:title]}' list because no method " + 
        "'#{list_generator_method}' exists"
    end
  end
  
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
  @items = options[:objects]
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
  @javascripts = javascripts_full_list
  @stylesheets = stylesheets_full_list
  asset('frames.html', erb(:frames))
end

def class_list(root = Registry.root)
  out = ""
  children = run_verifier(root.children)
  if root == Registry.root
    children += @items.select {|o| o.namespace.is_a?(CodeObjects::Proxy) }
  end
  children.reject {|c| c.nil? }.sort_by {|child| child.path }.map do |child|
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