Getting Started with YARD
=========================

There are a few ways which YARD can be of use to you or your project. This 
document will cover the most common ways to use YARD:

* [Documenting Code with YARD](#docing)
* [Using YARD to Generate Documentation](#using)
* [Extending YARD](#extending)
* [Templating YARD](#templating)
* [Plugin Support](#plugins)

<a name="docing"></a>
Documenting Code with YARD
==========================

By default, YARD is compatible with the same RDoc syntax most Ruby developers
are already familiar with. However, one of the biggest advantages of YARD is
the extended meta-data syntax, commonly known as "tags", that you can use
to express small bits of information in a structured and formal manner. While
RDoc syntax expects you to describe your method in a completely free-form
manner, YARD recommends declaring your parameters, return types, etc. with
the `@tag` syntax, which makes outputting the documentation more consistent
and easier to read. Consider the RDoc documentation for a method reverse:

    # Converts the object into textual markup given a specific `format` 
    # (defaults to `:html`)
    #
    # == Parameters:
    # format::
    #   A Symbol declaring the format to convert the object to. This 
    #   can be `:text` or `:html`.
    #
    # == Returns:
    # A string representing the object in a specified
    # format.
    #
    def to_format(format = :html)
      # format the object
    end
    
While this may seem easy enough to read and understand, it's hard for a machine
to properly pull this data back out of our documentation. Also we've tied our
markup to our content, and now our documentation becomes hard to maintain if
we decide later to change our markup style (maybe we don't want the ":" suffix
on our headers anymore).

In YARD, we would simply define our method as:

    # Converts the object into textual markup given a specific format.
    #
    # @param [Symbol] format the format type, `:text` or `:html`
    # @return [String] the object converted into the expected format.
    def to_format(format = :html)
      # format the object
    end
    
Using tags we can add semantic metadata to our code without worrying about
presentation. YARD will handle presentation for us when we decide to generate
documentation later.

Adding Tags to Documentation
----------------------------

The tag syntax that YARD uses is the same @tag-style syntax you may have seen 
if you've ever coded in Java, Python, PHP, Objective-C or a myriad of other 
languages. The following tag adds an author tag to your class:

    # @author Loren Segal
    class MyClass
    end

To allow for large amounts of text, the @tag syntax will recognize any indented
lines following a tag as part of the tag data. For example:

    # @deprecated Use {#my_new_method} instead of this method because
    #   it uses a library that is no longer supported in Ruby 1.9.
    #   The new method accepts the same parameters.
    def mymethod
    end

Declaring Types
---------------

Some tags also have an optional "types" field which let us declare a list of
types associated with the tag. For instance, a return tag can be declared
with or without a types field.

    # @return [String, nil] the contents of our object or nil
    #   if the object has not been filled with data.
    def validate; end
    
    # We don't care about the "type" here:
    # @return the object
    def to_obj; end
    
The list of types is in the form `[type1, type2, ...]` and is mostly free-form,
so we can also specify duck-types or constant values. For example:

    # @param [#to_s] argname any object that responds to `#to_s`
    # @param [true, false] argname only true or false
    
Note the the latter example can be replaced by the meta-type "Boolean", and
numeric types can be replaced by "Number". These meta-types are by convention
only, but are recommended.
    
List types can be specified in the form `CollectionClass<ElementType, ...>`.
For instance, consider the following Array that holds a set of Strings and
Symbols:
  
    # @param [Array<String, Symbol>] list the list of strings and symbols.

<a name="taglist"></a>
List of Tags
------------
    
A list of common tags and example usage is below:

  * `@abstract`: Marks a class/module/method as abstract with optional
    implementor information.
    
        @abstract Subclass and override {#run} to implement a custom Threadable class.

  * `@author`: List the author(s) of a class/method

        @author Full Name

  * `@deprecated`: Marks a method/class as deprecated with an optional
    reason.

        @deprecated Describe the reason or provide alt. references here

  * `@example`: Show an example snippet of code for an object. The
    first line is an optional title.

        @example Reverse a string
          "mystring.reverse" #=> "gnirtsym"

  * `@option`: Describe an options hash in a method. The tag takes the
    name of the options parameter first, followed by optional types,
    the option key name, an optional default value for the key and a 
    description of the option.

        # @param [Hash] opts the options to create a message with.
        # @option opts [String] :subject The subject
        # @option opts [String] :from ('nobody') From address
        # @option opts [String] :to Recipient email
        # @option opts [String] :body ('') The email's body 
        def send_email(opts = {})
        end 

  * `@overload`: Describe that your method can be used in various
    contexts with various parameters or return types. The first
    line should declare the new method signature, and the following
    indented tag data will be a new documentation string with its
    own tags adding metadata for such an overload.

        # @overload set(key, value)
        #   Sets a value on key
        #   @param [Symbol] key describe key param
        #   @param [Object] value describe value param
        # @overload set(value)
        #   Sets a value on the default key `:foo`
        #   @param [Object] value describe value param
        def set(*args)
        end
        
  * `@param`: Defines method parameters

        @param [optional, types, ...] argname description
        
  * `@private`: Defines an object as private. This exists for classes,
    modules and constants that do not obey Ruby's visibility rules. For
    instance, an inner class might be considered "private", though Ruby
    would make no such distinction. By declaring the @private tag, the
    class can be hidden from documentation by using the `--no-private`
    command-line switch to yardoc (see {file:README.md}).
    
        @private

  * `@raise`: Describes an Exception that a method may throw

        @raise [ExceptionClass] description

  * `@return`: Describes return value of method
  
        @return [optional, types, ...] description
        
  * `@see`: "See Also" references for an object. Accepts URLs or
    other code objects with an optional description at the end.
  
        @see http://example.com Description of URL
        @see SomeOtherClass#method
        
  * `@since`: Lists the version the feature/object was first added
  
        @since 1.2.4
        
  * `@todo`: Marks a TODO note in the object being documented

        @todo Add support for Jabberwocky service
          There is an open source Jabberwocky library available 
          at http://somesite.com that can be integrated easily
          into the project.

  * `@version`: Lists the version of a class, module or method
  
        @version 1.0

  * `@yield`: Describes the block. Use types to list the parameter
    names the block yields.

        # for block {|a, b, c| ... }
        @yield [a, b, c] Description of block

  * `@yieldparam`: Defines parameters yielded by a block

        @yieldparam [optional, types, ...] argname description

  * `@yieldreturn`: Defines return type of a block

        @yieldreturn [optional, types, ...] description
        
Other Extended Syntax
---------------------

**Reference Tags**

To minimize rewriting of documentation and to ease maintenance, a special
tag syntax is allowed to reference tags from other objects. Doing this allows
a tag to be added as meta-data for multiple objects. A full example of this
syntax is found in the {file:Tags.md#reftags Tags} file.

**Inter-Document Links**

YARD supports a special syntax to link to other code objects or files.
The syntax is `{ObjectName#method OPTIONAL_TITLE}`. This syntax is acceptable
anywhere in documentation with the exception of the @see tag, which 
automatically links its data.

<a name="using"></a>
Using YARD to Generate Documentation
====================================

Obviously since YARD is a documentation tool, one of its primary goals is
to generate documentation for a variety of formats, most commonly HTML. The
`yardoc` tool that is installed with YARD allows you to quickly export code
documentation to HTML document files. In addition to this, YARD ships with
two more tools allowing you to quickly view `ri`-style documentation for
a specific class or method as well as an extra tool to generate UML diagrams
for your code using [Graphviz][graphviz]. An overview of these tools can
be found in the {file:README.md README} under the Usage section.

<a name="extending"></a>
Extending YARD
==============

There are many ways to extend YARD to support non-standard Ruby syntax (DSLs), 
add new meta-data tags or programmatically access the intermediate metadata
and documentation from code. An overview of YARD's full architecture can be
found in the {file:Overview.md} document.

For information on adding support for Ruby DSLs, see the {file:Handlers.md}
and {file:Parser.md} architecture documents.

For information on adding extra tags, see {file:Tags.md}.

For information on accessing the data YARD stores about your documentation,
look at the {file:CodeObjects.md} architecture document.

<a name="templating"></a>
Templating YARD
===============

In many cases you may want to change the style of YARD's templates or add extra
information after extending it. The {file:Templates.md} architecture
document covers the basics of how YARD's templating system works.

<a name="plugins"></a>
Plugin Support
==============

As of 0.4, YARD will automatically load any gem named with the prefix of
`yard-` or `yard_`. You can use this to load a custom plugin that 
[extend](#extending) YARD's functionality. A good example of this
is the [yard-rspec][yard-rspec] plugin, which adds [RSpec][rspec] specifications
to your documentation (`yardoc` and `yri`). You can try it out by installing
the gem or cloning the project and trying the example:

    $ gem install yard-rspec -s http://gemcutter.org
    or
    $ git clone git://github.com/lsegal/yard-spec-plugin

YARD also provides a way to temporarily disable plugins on a per-user basis.
To disable a plugin create the file `~/.yard/ignored_plugins` with a list
of plugin names separated by newlines. Note that the `.yard` directory might
not exist, so you may need to create it.

[graphviz]:http://www.graphviz.org
[yard-rspec]:http://github.com/lsegal/yard-spec-plugin
[rspec]:http://rspec.info
