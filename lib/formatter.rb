require 'erb'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

module YARD
  ##
  # Formats the code objects in the {Namespace} in a variety of formats
  # 
  # @author Loren Segal
  # @version 1.0
  class Formatter
    OUTPUT_FORMATS = [ :html, :xhtml, :xml ]
    
    ##
    # Formats an object as a specified output format. Default is +:html+.
    # 
    # @param [String, CodeObject] object the code object to format or the path to the code object
    # @param [Symbol] format the output format to generate documentation in. 
    #                        Defaults to +:html+, which is a synonym for +:xhtml+.
    # @see OUTPUT_FORMATS
    def format(object, format = :html)
      object = Namespace.at(object) if object.is_a? String
      erb = File.join(template_directory, "#{format}_formatter.erb")

      @object = object
      ERB.new(IO.read(erb), nil, ">").result(binding)
    end
    
    ## 
    # Directory for templates. Override this to load your own templates
    def template_directory
      File.join(File.dirname(__FILE__), '..', 'templates')
    end
  end
end

def link_to_path(name, from_path = nil, label = nil)
  return "<a href='#instance_method-#{name[1..-1]}'>#{label || name}</a>" if name =~ /^\#/ && from_path.nil?
  
  if from_path
    obj = Namespace.find_from_path(from_path, name)
  else
    obj = Namespace.at(name)
  end
  
  label = name if label.nil?
  if obj && obj.is_a?(ConstantObject) then
    "<a href='#{obj.parent.path.gsub("::","_")}.html#const-#{obj.name}'>#{label}</a>"
  elsif obj && obj.is_a?(MethodObject) 
    "<a href='#{obj.parent.path.gsub("::","_")}.html##{obj.scope}_method-#{obj.name}'>#{label}</a>"
  elsif obj
    "<a href='#{obj.path.gsub("::","_")}.html'>#{label}</a>"
  else
    name
  end
end

SMP = SM::SimpleMarkup.new
SMH = SM::ToHtml.new

class String
  def to_html(path = nil)
    SMP.convert(self, SMH).gsub(/\A<p>|<\/p>\Z/,'').resolve_links(path)
  end
  
  def resolve_links(path = nil)
    t, re = self, /\{(.+?)\}/
    while t =~ re
      t.sub!(re, "<tt>" + link_to_path($1, path) + "</tt>")
    end
    t
  end
end

class NilClass
  def to_html(path = nil)
    ""
  end
end