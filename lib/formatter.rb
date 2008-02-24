require 'rubygems'
require 'erubis'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'

SMP = SM::SimpleMarkup.new
SMH = SM::ToHtml.new

module YARD
  ##
  # Formats the code objects in the {Namespace} in a variety of formats
  # 
  # @author Loren Segal
  # @version 1.0
  class Formatter
    ##
    # Formats an object as a specified output format. Default is +:html+.
    # 
    # @param format the output format to generate documentation in. 
    #               Defaults to +:html+, which is a synonym for <tt>:xhtml</tt>
    # @param template the template sub directory to use, default is <tt>:default</tt>
    # @see OUTPUT_FORMATS
    def format(object, format, template)
      object = Namespace.at(object) if object.is_a? String
      @object, @format, @template = object, format, template
      render(@object.type)
    end
    
    ## 
    # Directory for templates. Override this to load your own templates
    def template_directory
      File.join(File.dirname(__FILE__), '..', 'templates')
    end
    
    def render(type, format = @format, template = @template)
      formatter = self
      _binding = @object ? @object.instance_eval("binding") : binding 
      filename = File.join(template_directory, template.to_s, format.to_s, "#{type}.erb")
      Erubis::Eruby.new("<% extend #{format.to_s.capitalize}Formatter %>\n" + 
                IO.read(filename), :trim => true).result(_binding)
    rescue => e
      STDERR.puts "Could not render template #{filename}: #{e.message}"
      STDERR.puts e.backtrace[0, 5].map {|x| "\t#{x}" }
      STDERR.puts
    end
  end
  
  module HtmlFormatter
    def link_to_path(name, from_path = nil, label = nil)
      return "<a href='#instance_method-#{name[1..-1]}'>#{label || name}</a>" if name =~ /^\#/ && from_path.nil?

      if from_path
        obj = Namespace.find_from_path(from_path, name)
      else
        obj = Namespace.at(name)
      end

      label = name if label.nil?
      if obj
        file = (obj.parent || obj).path.gsub("::","_") + ".html"
        case obj
          when ConstantObject
            "<a href='#{file}#const-#{obj.name}'>#{label}</a>"
          when ClassVariableObject
            "<a href='#{file}#cvar-#{obj.name}'>#{label}</a>"
          when MethodObject
            "<a href='#{file}##{obj.scope}_method-#{obj.name}'>#{label}</a>"
          else
            "<a href='#{obj.path.gsub("::","_")}.html'>#{label}</a>"
        end
      else
        name
      end
    end

    def to_html(text, path = @object)
      resolve_links(SMP.convert(text || "", SMH).gsub(/\A<p>|<\/p>\Z/,''), path)
    end

    def resolve_links(text, path)
      text.gsub(/\{(.+?)\}/) {|match| "<tt>" + link_to_path(match, path) + "</tt>" }
    end
  end
  
  class CodeObject
    def to_s(format = :html, template = :default)
      Formatter.new.format(self, format, template)
    end
  end
end