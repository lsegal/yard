# frozen_string_literal: true

include T('default/layout/html')

def layout
  @path =
    if !object || object.is_a?(String)
      nil
    elsif defined?(@file) && @file
      @file.path
    elsif !object.is_a?(YARD::CodeObjects::NamespaceObject)
      object.parent.path
    else
      object.path
    end

  erb(:layout)
end

# @return [Array<String>] core javascript files for the Aliki layout
def javascripts
  %w[
    js/theme-toggle.js
    js/search_navigation.js
    js/search_data.js
    js/search_ranker.js
    js/search_controller.js
    js/c_highlighter.js
    js/bash_highlighter.js
    js/aliki.js
  ]
end

# @return [Array<String>] core stylesheet files for the Aliki layout
def stylesheets
  %w[css/rdoc.css css/yard.css]
end

def aliki_body_class
  if defined?(@file) && @file
    'file'
  elsif object.is_a?(CodeObjects::Base) && !object.root?
    object.type.to_s
  else
    'file'
  end
end

def aliki_root_prefix
  url_for_file('index.html').sub(/index\.html\z/, '')
end

def aliki_title
  if options.title && @page_title != options.title
    "#{@page_title} - #{options.title}"
  else
    @page_title
  end
end

def aliki_nav_files
  (options.files || []).reject do |file|
    file == options.readme && file == object
  end
end

def aliki_nav_objects
  run_verifier(Registry.all(:class, :module)).sort_by(&:path)
end

def aliki_nav_methods(scope)
  return [] unless object.is_a?(CodeObjects::NamespaceObject)

  methods = object.meths(:inherited => false, :included => !options.embed_mixins.empty?)
  run_verifier(methods).
    select {|method| method.scope == scope }.
    sort_by {|method| method.name.to_s }
end
