require 'erb'

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
    def initialize(object, format = :html)
      object = Namespace.at(object) if object.is_a? String
      erb = File.join(template_directory, "#{format}_formatter.erb")

      @object = object
      File.open(object.path.gsub("::","_") + ".html", "w") {|f| f.write ERB.new(IO.read(erb), nil, ">").result(binding) }
    end
    
    ## 
    # Directory for templates. Override this to load your own templates
    def template_directory
      File.join(File.dirname(__FILE__), '..', 'templates')
    end
  end
end