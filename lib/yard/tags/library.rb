module YARD
  module Tags
    ##
    # Holds all the registered meta tags. If you want to extend YARD and add
    # a new meta tag, you can do it in one of two ways.
    #
    # == Method #1
    # Write your own +tagname_tag+ method that takes the raw text as a parameter.
    # Example:
    #   def mytag_tag(text)
    #     Tag.parse_tag("mytag", text)
    #   end
    #
    # This will allow you to use @mytag TEXT to add meta data to classes through
    # the docstring. {Tag} has a few convenience factory methods to create 
    #
    # == Method #2
    # Use {Library::define_tag!} to define a new tag by passing the tag name
    # and the factory method to use when creating the tag. These definitions will
    # be auto expanded into ruby code similar to what is shown in method #1. If you
    # do not provide a factory method to use, it will default to {Tag::parse_tag}
    # Example:
    #   define_tag :param, :with_types_and_name
    #   define_tag :author
    #
    # The first line will expand to the code:
    #   def param_tag(text) Tag.parse_tag_with_types_and_name(text) end
    #
    # The second line will expand to:
    #   def author_tag(text) Tag.parse_tag(text) end
    #
    # @see Library::define_tag
    class Library
      class << self
        attr_reader :labels
        attr_accessor :default_factory
        
        def default_factory
          @default_factory ||= DefaultFactory.new
        end
        
        def default_factory=(factory)
          @default_factory = factory.is_a?(Class) ? factory.new : factory
        end
      
        ## 
        # Sorts the labels lexically by their label name, often used when displaying
        # the tags.
        # 
        # @return [Array<Symbol>, String] the sorted labels as an array of the tag name and label
        def sorted_labels
          labels.sort_by {|a| a.last.downcase }
        end
      
        ##
        # Convenience method to define a new tag using one of {Tag}'s factory methods, or the
        # regular {Tag::parse_tag} factory method if none is supplied.
        #
        # @param [#to_s] tag the tag name to create
        # @param meth the {Tag} factory method to call when creating the tag
        def define_tag(label, tag, meth = "")
          define_method("#{tag}_tag") do |text, raw_text| 
            send_to_factory(tag, meth, text, raw_text)
          end

          @labels ||= SymbolHash.new(false)
          @labels.update(tag => label)
          tag
        end
      end
      
      private
      
      def send_to_factory(tag_name, meth, text, raw_text)
        meth = meth.to_s
        send_name = "parse_tag" + (meth.empty? ? "" : "_" + meth)
        if @factory.respond_to?(send_name)
          arity = @factory.method(send_name).arity
          @factory.send send_name, tag_name, text, *(arity == 3 ? [raw_text] : [])
        else
          raise NoMethodError, "Factory #{@factory.class_name} does not implement factory method :#{meth}."
        end
      end
      
      public
      
      def initialize(factory = Library.default_factory)
        @factory = factory
      end
      
      define_tag "Parameters",        :param,       :with_types_and_name
      define_tag "Yield Parameters",  :yieldparam,  :with_types_and_name
      define_tag "Yields",            :yield,       :with_types
      define_tag "Default Value",     :default,     :with_name
      define_tag "Returns",           :return,      :with_types
      define_tag "Deprecated",        :deprecated
      define_tag "Author",            :author
      define_tag "Raises",            :raise,       :with_name
      define_tag "See Also",          :see
      define_tag "Since",             :since
      define_tag "Version",           :version
      define_tag "API Visibility",    :api
      define_tag "Todo Item",         :todo      
      define_tag "Example",           :example,     :with_raw_title_and_text
    end
  end
end