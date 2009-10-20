require 'rubygems'

module YARD
  module Templates::Helpers
    module MarkupHelper
      MARKUP_PROVIDERS = {
        :markdown => [
          {:lib => :bluecloth, :const => 'BlueCloth'},
          {:lib => :maruku, :const => 'Maruku'},
          {:lib => :"rpeg-markdown", :const => "PEGMarkdown"},
          {:lib => :rdiscount, :const => "RDiscount"}
        ],
        :textile => [
          {:lib => :redcloth, :const => 'RedCloth'}
        ]
      }

      begin
        require 'rdoc/markup'
        require 'rdoc/markup/to_html'
        SimpleMarkup = RDoc::Markup.new
      rescue Gem::LoadError
        raise
      rescue LoadError
        require 'rubygems'
        require 'rdoc/markup/simple_markup'
        require 'rdoc/markup/simple_markup/to_html'
        SimpleMarkup = SM::SimpleMarkup.new
      end

      private
      
      # Attempts to load the first valid markup provider in {MARKUP_PROVIDERS}.
      # If a provider is specified, immediately try to load it.
      # 
      # On success this sets `@markup_provider` and `@markup_class` to
      # the provider name and library constant class/module respectively for
      # the loaded proider.
      # 
      # On failure this method will inform the user that no provider could be
      # found and exit the program.
      def load_markup_provider(type = options[:markup])
        return if type == :rdoc || (@markup_cache && @markup_cache[type])
        @markup_cache ||= {}
        @markup_cache[type] ||= {}
        
        providers = MARKUP_PROVIDERS[type]
        if options[:markup_provider]
          providers = MARKUP_PROVIDERS[type].select {|p| p[:lib] == options[:markup_provider] }
        end
        
        if providers == nil || providers.empty?
          STDERR.puts "Invalid markup type '#{options[:markup]}'"
          exit
        end
        
        # Search for provider, return the library class name as const if found
        providers.each do |provider|
          begin require provider[:lib].to_s; rescue LoadError; next end
          @markup_cache[type][:provider] = provider[:lib] # Cache the provider
          @markup_cache[type][:class] = Kernel.const_get(provider[:const])
          return
        end
        
        # Show error message telling user to install first potential provider
        name, lib = providers.first[:const], providers.first[:lib]
        STDERR.puts "Missing #{name} gem for #{options[:markup].to_s.capitalize} formatting. Install it with `gem install #{lib}`"
        exit
      end
      
      # Gets the markup provider class/module constant for a markup type
      # Call {#load_markup_provider} before using this method.
      # 
      # @param [Symbol] the markup type (:rdoc, :markdown, etc.)
      # @return [Class] the markup class
      def markup_class(type = options[:markup])
        type == :rdoc ? SimpleMarkup : @markup_cache[type][:class]
      end
      
      # Gets the markup provider name for a markup type
      # Call {#load_markup_provider} before using this method.
      # 
      # @param [Symbol] the markup type (:rdoc, :markdown, etc.)
      # @return [Symbol] the markup provider name (usually the gem name of the library)
      def markup_provider(type = options[:markup])
        type == :rdoc ? nil : @markup_cache[type][:provider]
      end
    end
  end
end
