require 'ostruct'

module YARD
  module Templates
    # An Options class containing default options for base template rendering. For
    # options specific to generation of HTML output, see {CLI::YardocOptions}.
    # 
    # @see CLI::YardocOptions
    class TemplateOptions < YARD::Options
      # @return [Symbol] the template output format
      default_attr :format, :text
      
      # @return [Symbol] the template name used to render output
      default_attr :template, :default
      
      # @return [Symbol] the markup format to use when parsing docstrings
      default_attr :markup, :rdoc # default is :rdoc but falls back on :none
      
      # @return [String] the default return type for a method with no return tags
      default_attr :default_return, "Object"
      
      # @return [Boolean] whether void methods should show "void" in their signature
      default_attr :hide_void_return, false
      
      # @return [Boolean] whether code blocks should be syntax highlighted
      default_attr :highlight, true

      # @return [Class] the markup provider class for the markup format
      attr_accessor :markup_provider
      
      # @return [OpenStruct] an open struct containing any global state across all
      #   generated objects in a template.
      default_attr :globals, lambda { OpenStruct.new }
      alias __globals globals
      
      # @return [CodeObjects::Base] the main object being generated in the template
      attr_accessor :object
      
      # @return [Symbol] the template type used to generate output
      attr_accessor :type
      
      # @return [Boolean] whether serialization should be performed
      default_attr :serialize, false
      
      # @return [Serializers::Base] the serializer used to generate links and serialize
      #   output. Serialization output only occurs if {#serialize} is +true+.
      attr_accessor :serializer
      
      # @deprecated use {#highlight} instead.
      # @return [Boolean] whether highlighting should be ignored
      attr_reader :no_highlight
      undef no_highlight
      def no_highlight; !highlight end
      def no_highlight=(value) self.highlight = !value end

      # @return [String] the title of a given page
      attr_accessor :page_title
    end
  end
end
