# frozen_string_literal: true

require 'json'

include T('default/fulldoc/html')

def init
  options.objects = objects = run_verifier(options.objects)

  return serialize_onefile if options.onefile

  generate_assets
  serialize('_index.html')
  options.files.each_with_index do |file, _i|
    serialize_file(file, file.title)
  end

  options.delete(:objects)

  objects.each do |object|
    begin
      serialize(object)
    rescue StandardError => e
      path = options.serializer.serialized_path(object)
      log.error "Exception occurred while generating '#{path}'"
      log.backtrace(e)
    end
  end
end

def generate_assets
  layout_template = Templates::Engine.template(:aliki, :layout, :html)
  layout = Object.new.extend(layout_template)
  (layout.javascripts + layout.stylesheets).uniq.each do |file|
    next if file == 'js/search_data.js'

    asset(file, File.read(layout_template.find_file(file)))
  end

  asset('js/search_data.js', aliki_search_data)
end

def aliki_search_data
  entries = []
  searchable_objects.each do |object|
    entries << aliki_search_entry(object)
  end

  "var search_data = #{JSON.generate(:index => entries.compact)};"
end

def searchable_objects
  objects = Registry.all(:class, :module, :method, :constant, :classvariable)
  run_verifier(objects).reject do |object|
    object.respond_to?(:root?) && object.root?
  end
end

def aliki_search_entry(object)
  path = url_for(object, nil, false)
  return unless path

  {
    :name => aliki_search_name(object),
    :full_name => object.path,
    :type => aliki_search_type(object),
    :path => path
  }.tap do |entry|
    snippet = aliki_search_snippet(object)
    entry[:snippet] = snippet unless snippet.empty?
  end
end

def aliki_search_name(object)
  if object.respond_to?(:name)
    object.name.to_s
  else
    object.path.to_s
  end
end

def aliki_search_type(object)
  case object
  when CodeObjects::ClassObject
    'class'
  when CodeObjects::ModuleObject
    'module'
  when CodeObjects::MethodObject
    object.scope == :class ? 'class_method' : 'instance_method'
  when CodeObjects::ConstantObject, CodeObjects::ClassVariableObject
    'constant'
  else
    object.type.to_s
  end
end

def aliki_search_snippet(object)
  return '' unless object.respond_to?(:docstring)

  summary = object.docstring.summary.to_s.strip.gsub(/\s+/, ' ')
  h(summary)
end
