module YARD
  module Tags
    # Holds all the registered meta tags. If you want to extend YARD and add
    # a new meta tag, you can do it in one of two ways.
    #
    # == Method #1
    # Use {Library.define_tag} to define a new tag by passing the tag name
    # and the factory method to use when creating the tag. These definitions will
    # be auto expanded into ruby code similar to what is shown in method #2. If you
    # do not provide a factory method to use, it will default to {DefaultFactory#parse_tag}
    # Example:
    #   define_tag "Parameter", :param, :with_types_and_name
    #   define_tag "Author", :author
    #
    # The first line will expand to the code:
    #   def param_tag(text) tag_factory.parse_tag_with_types_and_name(text) end
    #
    # The second line will expand to:
    #   def author_tag(text) tag_factory.parse_tag(text) end
    #
    # Note that +tag_factory+ is the factory object used to parse tags. This value
    # defaults to the {DefaultFactory} class and can be set by changing {Library.default_factory}.
    #
    # == Method #2
    # Write your own +tagname_tag+ method that takes the raw text as a parameter.
    # Example:
    #   def mytag_tag(text)
    #     # parse your tag contents here
    #   end
    #
    # This will allow you to use @mytag TEXT to add meta data to classes through
    # the docstring. You can use the {Library#factory} object to help parse standard
    # tag syntax.
    #
    # == Adding/Changing the Tag Syntax
    # If you have specialized tag parsing needs you can substitute the {#factory}
    # object with your own by setting {Library.default_factory= Library.default_factory}
    # to a new class with its own parsing methods before running YARD. This is useful
    # if you want to change the syntax of existing tags (@see, @since, etc.)
    #
    # @see DefaultFactory
    # @see Library.define_tag
    class Library
      class << self
        attr_reader :labels

        def instance
          @instance ||= new
        end

        def default_factory
          @default_factory ||= DefaultFactory.new
        end

        # Replace the factory object responsible for parsing tags by setting
        # this to an object (or class) that responds to +parse_TAGNAME+ methods
        # where +TAGNAME+ is the name of the tag.
        #
        # You should set this value before performing any source parsing with
        # YARD, otherwise your factory class will not be used.
        #
        # @example
        #   YARD::Tags::Library.default_factory = MyFactory
        #
        # @param [Class, Object] factory the factory that parses all tags
        #
        # @see DefaultFactory
        def default_factory=(factory)
          @default_factory = factory.is_a?(Class) ? factory.new : factory
        end

        # Returns the factory method used to parse the tag text for a specific tag
        #
        # @param [Symbol] tag the tag name
        # @return [Symbol] the factory method name for the tag
        # @return [Class<Tag>,Symbol] the Tag class to use to parse the tag
        #   or the method to call on the factory class
        # @return [nil] if the tag is freeform text
        # @since 0.6.0
        def factory_method_for(tag)
          @factory_methods[tag]
        end

        # Returns the factory method used to parse the tag text for a specific
        # directive
        #
        # @param [Symbol] directive the directive name
        # @return [Symbol] the factory method name for the tag
        # @return [Class<Tag>,Symbol] the Tag class to use to parse the tag or
        #   the methods to call on the factory class
        # @return [nil] if the tag is freeform text
        # @since 0.8.0
        def factory_method_for_directive(directive)
          @directive_factory_classes[directive]
        end

        # Sets the list of tags to display when rendering templates. The order of
        # tags in the list is also significant, as it represents the order that
        # tags are displayed in templates.
        #
        # You can use the {Array#place} to insert new tags to be displayed in
        # the templates at specific positions:
        #
        #   Library.visible_tags.place(:mytag).before(:return)
        #
        # @return [Array<Symbol>] a list of ordered tags
        # @since 0.6.0
        attr_accessor :visible_tags

        # Sets the list of tags that should apply to any children inside the
        # namespace they are defined in. For instance, a "@since" tag should
        # apply to all methods inside a module it is defined in. Transitive
        # tags can be overridden by directly defining a tag on the child object.
        #
        # @return [Array<Symbol>] a list of transitive tags
        # @since 0.6.0
        attr_accessor :transitive_tags

        # Sorts the labels lexically by their label name, often used when displaying
        # the tags.
        #
        # @return [Array<Symbol>, String] the sorted labels as an array of the tag name and label
        def sorted_labels
          labels.sort_by {|a| a.last.downcase }
        end

        # Convenience method to define a new tag using one of {Tag}'s factory methods, or the
        # regular {DefaultFactory#parse_tag} factory method if none is supplied.
        #
        # @!macro [attach] yard.tag
        #   @!method $2_tag
        #   @!visibility private
        #   @yard.tag $2 [$3] $1
        # @param [#to_s] label the label used when displaying the tag in templates
        # @param [#to_s] tag the tag name to create
        # @param [#to_s, Class<Tag>] meth the {Tag} factory method to call when
        #   creating the tag or the name of the class to directly create a tag for
        def define_tag(label, tag, meth = nil)
          tag_meth = tag_method_name(tag)
          if meth.is_a?(Class) && Tag > meth
            class_eval <<-eof, __FILE__, __LINE__
              def #{tag_meth}(text)
                #{meth}.new(#{tag.inspect}, text)
              end
            eof
          else
            class_eval <<-eof, __FILE__, __LINE__
              def #{tag_meth}(text)
                send_to_factory(#{tag.inspect}, #{meth.inspect}, text)
              end
            eof
          end

          @labels ||= SymbolHash.new(false)
          @labels.update(tag => label)
          @factory_methods ||= SymbolHash.new(false)
          @factory_methods.update(tag => meth)
          tag
        end

        # @macro [attach] yard.directive
        #   @!method $1_directive
        #   @!visibility private
        #   @yard.directive $1 [$2] $-1
        # @overload define_directive(tag, tag_meth = nil, directive_class)
        #   Convenience method to define a new directive using a {Tag} factory
        #   method and {Directive} subclass that implements the directive
        #   callbacks.
        #
        #   @param [#to_s] tag the tag name of the directive
        #   @param [#to_s] tag_meth the tag factory method to use when
        #     parsing tag information
        #   @param [Class<Directive>] the directive class that implements the
        #     directive behaviour
        #   @see define_tag
        def define_directive(tag, tag_meth = nil, directive_class = nil)
          directive_meth = directive_method_name(tag)
          if directive_class.nil?
            tag_meth, directive_class = nil, tag_meth
          end
          class_eval <<-eof, __FILE__, __LINE__
            def #{directive_meth}(tag, parser)
              directive_call(tag, parser)
            end
          eof

          @factory_methods ||= SymbolHash.new(false)
          @factory_methods.update(tag => tag_meth)
          @directive_factory_classes ||= SymbolHash.new(false)
          @directive_factory_classes.update(tag => directive_class)

          tag
        end

        def tag_method_name(tag_name)
          tag_or_directive_method_name(tag_name)
        end

        def directive_method_name(tag_name)
          tag_or_directive_method_name(tag_name, 'directive')
        end

        private

        def tag_or_directive_method_name(tag_name, type = 'tag')
          "#{tag_name.to_s.gsub('.', '_')}_#{type}"
        end
      end

      private

      def send_to_factory(tag_name, meth, text)
        meth = meth.to_s
        send_name = "parse_tag" + (meth.empty? ? "" : "_" + meth)
        if @factory.respond_to?(send_name)
          arity = @factory.method(send_name).arity
          @factory.send(send_name, tag_name, text)
        else
          raise NoMethodError, "Factory #{@factory.class_name} does not implement factory method :#{meth}."
        end
      end

      # @return [Directive]
      def directive_call(tag, parser)
        meth = self.class.factory_method_for_directive(tag.tag_name)
        if meth <= Directive
          meth = meth.new(tag, parser)
          meth.call
          meth
        else
          meth.call(tag, parser)
        end
      end

      public

      # A factory class to handle parsing of tags, defaults to {default_factory}
      attr_accessor :factory

      def initialize(factory = Library.default_factory)
        self.factory = factory
      end

      def has_tag?(tag_name)
        tag_name && respond_to?(self.class.tag_method_name(tag_name))
      end

      def tag_create(tag_name, tag_buf)
        send(self.class.tag_method_name(tag_name), tag_buf)
      end

      def has_directive?(tag_name)
        tag_name && respond_to?(self.class.directive_method_name(tag_name))
      end

      # @return [Directive]
      def directive_create(tag_name, tag_buf, parser)
        meth = self.class.factory_method_for(tag_name)
        tag = send_to_factory(tag_name, meth, tag_buf)
        meth = self.class.directive_method_name(tag_name)
        send(meth, tag, parser)
      end

      # Marks a class/module/method as abstract with optional
      # implementor information.
      #
      # @example
      #   # @abstract Subclass and override {#run} to implement 
      #   #   a custom Threadable class.
      #   class Runnable
      #     def run; raise NotImplementedError end
      #   end
      define_tag "Abstract",           :abstract

      # Declares the API that the object belongs to. Does not display in
      # output, but useful for performing queries (+yardoc --query+). Any text is
      # allowable in this tag, and there are no predefined values.
      #
      # @note The special name +@api private+ does display a notice in
      #   documentation if it is listed, letting users know that the 
      #   method is not to be used by external components.
      # @example
      #   class Post
      #     # @api private
      #     def reset_table!; table.flush end
      #   end
      define_tag "API Visibility",     :api

      # Declares a readwrite attribute on a Struct or class.
      #
      # @note This attribute is only applicable on class docstrings
      # @deprecated Use the more powerful {tag:!attribute} directive instead.
      # @example
      #   # @attr [String] name the name of the structure
      #   # @attr [Fixnum] size the size of the structure
      #   class MyStruct < Struct; end
      define_tag "Attribute",          :attr,        :with_types_and_name

      # Declares a readonly attribute on a Struct or class.
      #
      # @note This attribute is only applicable on class docstrings
      # @deprecated Use the more powerful {tag:!attribute} directive instead.
      # @example
      #   # @attr_reader [String] name the name of the structure
      #   # @attr_reader [Fixnum] size the size of the structure
      #   class MyStruct < Struct; end
      define_tag "Attribute Getter",   :attr_reader, :with_types_and_name

      # Declares a writeonly attribute on a Struct or class.
      #
      # @note This attribute is only applicable on class docstrings
      # @deprecated Use the more powerful {tag:!attribute} directive instead.
      # @example
      #   # @attr_reader [String] name the name of the structure
      #   # @attr_reader [Fixnum] size the size of the structure
      #   class MyStruct < Struct; end
      define_tag "Attribute Setter",   :attr_writer, :with_types_and_name

      # List the author or authors of a class, module, or method.
      #
      # @example
      #   # @author Foo Bar <foo@bar.com>
      #   class MyClass; end
      define_tag "Author",             :author

      # Marks a method/class as deprecated with an optional description.
      # The description should be used to inform users of the recommended
      # migration path, and/or any useful information about why the object
      # was marked as deprecated.
      #
      # @example Deprecate a method with a replacement API
      #   # @deprecated Use {#bar} instead.
      #   def foo; end
      # @example Deprecate a method with no replacement
      #   class Thread
      #     # @deprecated Exiting a thread in this way is not reliable and
      #     #   can cause a program crash.
      #     def kill; end
      #   end
      define_tag "Deprecated",         :deprecated

      # Show an example snippet of code for an object. The first line
      # is an optional title.
      #
      # @example
      #   # @example Reverse a String
      #   #   "mystring".reverse #=> "gnirtsym"
      #   def reverse; end
      # @yard.signature Optional title
      #   Code block
      define_tag "Example",            :example,     :with_title_and_text

      # Adds an emphasized note at the top of the docstring for the object
      # 
      # @example
      #   # @note This method should only be used in outer space.
      #   def eject; end
      # @see tag:todo
      define_tag "Note",               :note

      # Describe an options hash in a method. The tag takes the
      # name of the options parameter first, followed by optional types,
      # the option key name, an optional default value for the key and a
      # description of the option.
      #
      # @example
      #   # @param [Hash] opts the options to create a message with.
      #   # @option opts [String] :subject The subject
      #   # @option opts [String] :from ('nobody') From address
      #   # @option opts [String] :to Recipient email
      #   # @option opts [String] :body ('') The email's body
      #   def send_email(opts = {}) end
      define_tag "Options Hash",       :option,      :with_options

      # Describe that your method can be used in various
      # contexts with various parameters or return types. The first
      # line should declare the new method signature, and the following
      # indented tag data will be a new documentation string with its
      # own tags adding metadata for such an overload.
      #
      # @example
      #   # @overload set(key, value)
      #   #   Sets a value on key
      #   #   @param [Symbol] key describe key param
      #   #   @param [Object] value describe value param
      #   # @overload set(value)
      #   #   Sets a value on the default key +:foo+
      #   #   @param [Object] value describe value param
      #   def set(*args) end
      # @yard.signature method_signature(parameters)
      #   Indented docstring for overload method
      define_tag "Overloads",          :overload,    OverloadTag

      # Documents a single method parameter with a given name, type
      # and optional description.
      #
      # @example
      #   # @param [String] the URL of the page to download
      #   def load_page(url) end
      define_tag "Parameters",         :param,       :with_types_and_name

      # Defines an object as private. This exists for classes,
      # modules and constants that do not obey Ruby's visibility rules. For
      # instance, an inner class might be considered "private", though Ruby
      # would make no such distinction. By declaring the @private tag, the
      # class can be hidden from documentation by using the +--no-private+
      # command-line switch to yardoc (see {file:README.md}).
      #
      # @note This method is not recommended for hiding undocumented or
      #   "unimportant" methods. This tag should only be used to mark objects
      #   private when Ruby visibility rules cannot do so. In Ruby 1.9.3, you
      #   can use +private_constant+ to declare constants (like classes or
      #   modules) as private, and should be used instead of +@private+.
      # @note If +@private+ is applied to a class or module, all methods within
      #   that namespace are also marked private.
      # @example
      #   # @private
      #   class InteralImplementation; end
      # @yard.signature
      define_tag "Private",            :private

      # Describes that a method may raise a given exception, with
      # an optional description of what it may mean.
      #
      # @example
      #   # @raise [AccountBalanceError] if the account does not have
      #   #   sufficient funds to perform the transaction
      #   def withdraw(amount) end
      define_tag "Raises",             :raise,       :with_types

      # Describes the return value (and type or types) of a method.
      # You can list multiple return tags for a method in the case
      # where a method has distinct return cases. In this case, each
      # case should begin with "if ...".
      #
      # @example A regular return value
      #   # @return [Fixnum] the size of the file
      #   def size; @file.size end
      # @example A method returns an Array or a single object
      #   # @return [String] if a single object was returned
      #   #   from the database.
      #   # @return [Array<String>] if multiple objects were
      #   #   returned.
      #   def find(query) end
      define_tag "Returns",            :return,      :with_types

      # "See Also" references for an object. Accepts URLs or
      # other code objects with an optional description at the end.
      # Note that the URL or object will be automatically linked by
      # YARD and does not need to be formatted with markup.
      #
      # @example
      #   # Synchronizes system time using NTP.
      #   # @see http://ntp.org/documentation.html NTP Documentation
      #   # @see NTPHelperMethods
      #   class NTPUpdater; end
      define_tag "See Also",           :see,         :with_name

      # Lists the version that the object was first added
      #
      # @example
      #   # @since 1.2.4
      #   def clear_routes; end
      define_tag "Since",              :since

      # Marks a TODO note in the object being documented.
      # For reference, objects with TODO items can be enumerated
      # from the command line with a simple command:
      #
      #   !!!sh
      #   mocker$ yard list --query '@todo'
      #   lib/mocker/mocker.rb:15: Mocker
      #   lib/mocker/report/html.rb:5: Mocker::Report::Html
      #
      # YARD can also be used to enumerate the TODO items from
      # a short script:
      #
      #   !!!ruby
      #   require 'yard'
      #   YARD::Registry.load!.all.each do |o|
      #     puts o.tag(:todo).text if o.tag(:todo)
      #   end
      #
      # @example
      #   # @todo Add support for Jabberwocky service.
      #   #   There is an open source Jabberwocky library available
      #   #   at http://jbrwcky.org that can be easily integrated.
      #   class Wonderlander; end
      # @see tag:note
      define_tag "Todo Item",          :todo

      # Lists the version of a class, module or method. This is
      # similar to a library version, but at finer granularity.
      # In some cases, version of specific modules, classes, methods
      # or generalized components might change independently between
      # releases. A version tag is used to infer the API compatibility
      # of a specific object.
      #
      # @example
      #   # The public REST API for http://jbrwcky.org
      #   # @version 2.0
      #   class JabberwockyAPI; end
      define_tag "Version",            :version

      # Describes what a method might yield to a given block.
      # The types specifier list should not list types, but names
      # of the parameters yielded to the block. If you define
      # parameters with +@yieldparam+, you do not need to define
      # the parameters in the type specification of +@yield+ as
      # well.
      #
      # @example
      #   # For a block {|a,b,c| ... }
      #   # @yield [a, b, c] Gives 3 random numbers to the block
      #   def provide3values(&block) yield(42, 42, 42) end
      # @see tag:yieldparam
      # @see tag:yieldreturn
      # @yard.signature [parameters] description
      define_tag "Yields",             :yield,       :with_types

      # Defines a parameter yielded by a block. If you define the
      # parameters with +@yieldparam+, you do not need to define
      # them via +@yield+ as well.
      #
      # @example
      #   # @yieldparam [String] name the name that is yielded
      #   def with_name(name) yield(name) end
      define_tag "Yield Parameters",   :yieldparam,  :with_types_and_name

      # Documents the value and type that the block is expected
      # to return to the method.
      #
      # @example
      #   # @yieldreturn [Fixnum] the number to add 5 to.
      #   def add5_block(&block) 5 + yield end
      # @see tag:return
      define_tag "Yield Returns",      :yieldreturn, :with_types

      # @yard.signature [r | w | rw] attribute_name
      #   Indented attribute docstring
      define_directive :attribute, :with_types_and_title, AttributeDirective

      # @yard.signature
      define_directive :endgroup,                         EndGroupDirective

      define_directive :group,                            GroupDirective

      # @yard.signature [attach | new] optional_name
      #   Optional macro expansion data
      define_directive :macro, :with_types_and_title,     MacroDirective

      # @yard.signature method_signature(parameters)
      #   Indented method docstring
      define_directive :method, :with_title_and_text,     MethodDirective

      # @yard.signature [language] code
      define_directive :parse, :with_types,               ParseDirective

      # Sets the scope of a DSL method. Only applicable to DSL method
      # calls. Acceptable values are 'class' or 'instance'
      # @yard.signature class | instance
      define_directive :scope,                            ScopeDirective

      # Sets the visibility of a DSL method. Only applicable to
      # DSL method calls. Acceptable values are public, protected, or private.
      # @yard.signature public | protected | private
      define_directive :visibility,                       VisibilityDirective

      self.visible_tags = [:abstract, :deprecated, :note, :todo, :example, :overload,
        :param, :option, :yield, :yieldparam, :yieldreturn, :return, :raise,
        :see, :author, :since, :version]

      self.transitive_tags = [:since, :api]
    end
  end
end
