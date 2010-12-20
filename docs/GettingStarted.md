Getting Started with YARD
=========================

There are a few ways which YARD can be of use to you or your project. This 
document will cover the most common ways to use YARD:

* [Documenting Code with YARD](#docing)
* [Using YARD to Generate Documentation](#using)
* [Configuring YARD](#config)
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

Which Markup Format?
--------------------

YARD does not impose a specific markup. The above example uses standard RDoc
markup formatting, but YARD also supports textile and markdown via the 
command-line switch or `.yardopts` file (see below). This means that you are
free to use whatever formatting you like. This guide is actually written
using markdown. YARD, however, does add a few important syntaxes that are 
processed no matter which markup formatting you use, such as tag support 
and inter-document linking. These syntaxes are discussed below.

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
    
### List of Tags

A list of tags can be found in {file:docs/Tags.md#taglist}    
    
### Reference Tags

To reduce the amount of duplication in writing documentation for repetitive
code, YARD introduces "reference tags", which are not quite tags, but not
quite docstrings either. In a sense, they are tag (and docstring) modifiers.
Basically, any docstring (or tag) that begins with "(see OTHEROBJECT)" will
implicitly link the docstring or tag to the "OTHEROBJECT", copying any data
from that docstring/tag into your current object. Consider the example:

    class MyWebServer
      # Handles a request
      # @param [Request] request the request object
      # @return [String] the resulting webpage
      def get(request) "hello" end

      # (see #get)
      def post(request) "hello" end
    end
    
The above `#post` method takes the docstring and all tags (`param` and `return`)
of the `#get` method. When you generate HTML documentation, you will see this
duplication automatically, so you don't have to manually type it out. We can
also add our own custom docstring information below the "see" reference, and
whatever we write will be appended to the docstring:

    # (see #get)
    # @note This method may modify our application state!
    def post(request) self.state += 1; "hello" end
    
Here we added another tag, but we could have also added plain text. The
text must be appended *after* the `(see ...)` statement, preferably on
a separate line.

Note that we don't have to "refer" the whole docstring. We can also link 
individual tags instead. Since "get" and "post" actually have different 
descriptions, a more accurate example would be to only refer our parameter 
and return tags:

    class MyWebServer
      # Handles a GET request
      # @param [Request] request the request object
      # @return [String] the resulting webpage
      def get(request) "hello" end
      
      # Handles a POST request
      # @note This method may modify our application state!
      # @param (see #get)
      # @return (see #get)
      def post(request) self.state += 1; "hello" end
    end
    
The above copies all of the param and return tags from `#get`. Note that you
cannot copy individual tags of a specific type with this syntax.

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
    
We mentioned that these type fields are "mostly" free-form. In truth, they
are defined "by convention". To view samples of common type specifications
and recommended conventions for writing type specifications, see 
{http://yardoc.org/types.html}. Note that these conventions may change every now 
and then, although we are working on a more "formal" type specification proposal.

Inter-document Linking
----------------------

YARD supports a special syntax to link to other code objects, URLs, files,
or embed docstrings between documents. This syntax has the general form
of `{Name OptionalTitle}` (where `OptionalTitle` can have spaces, but `Name`
cannot).

### Linking Objects

To link another "object" (class, method, module, etc.), use the format:

    {ObjectName#method OPTIONAL_TITLE}
    {Class::CONSTANT My constant's title}
    {#method_inside_current_namespace}
    
Without an explicit title, YARD will use the relative path to the object as
the link name. Note that you can also use relative paths inside the object
path to refer to an object inside the same namespace as your current docstring.

Note that the `@see` tag automatically links its data. You should not use
the link syntax in this tag:

    # @see #methodname   <- Correct.
    # @see {#methodname} <- Incorrect.
    
### Linking URLs

URLs are also linked using this `{...}` syntax:

    {http://example.com Optional Title}
    {mailto:email@example.com}

### Linking Files

Files can also be linked using this same syntax but by adding the `file:`
prefix to the object name. Files refer to extra readme files you added
via the command-line. Consider the following examples:

    {file:docs/GettingStarted.md Getting Started}
    {file:mypage.html Name#anchor}
    
As shown, you can also add an optional `#anchor` if the page is an HTML link.

### Embedding Docstrings

We saw the `(see ...)` syntax above, which allowed us to link an entire docstring
with another. Sometimes, however, we just want to copy docstring text without
tags. Using the same `{...}` syntax, but using the `include:` prefix, we can
embed a docstring (minus tags) at a specific point in the text.

    # This class is cool
    # @abstract
    class Foo; end
    
    # This is another class. {include:Foo} too!
    class Bar; end
    
The docstring for Bar becomes: 

    "This is another class. This class is cool too!"

Note that this prefix currently only works for objects.

<a name="using"></a>
Using YARD to Generate Documentation
====================================

`yard` Executable
-----------------

YARD ships with a single executable aptly named `yard`. In addition to
generating standard documentation for your project, you would use this tool 
if you wanted to: 

* Document all installed gems
* Run a local documentation server
* Generate UML diagrams using [Graphviz][graphviz]
* View `ri`-style documentation
* Diff your documentation
* Analyze documentation statistics.

The following commands are available in YARD 0.6.x (see `yard help` for a 
full list):

    Usage: yard <command> [options]

    Commands:
    config   Views or edits current global configuration
    diff     Returns the object diff of two gems or .yardoc files
    doc      Generates documentation
    gems     Builds YARD index for gems
    graph    Graphs class diagram using Graphviz
    help     Retrieves help for a command
    ri       A tool to view documentation in the console like `ri`
    server   Runs a local documentation server
    stats    Prints documentation statistics on a set of files

Note that `yardoc` is an alias for `yard doc`, and `yri` is an alias for
`yard ri`. These commands are maintained for backwards compatibility.

`.yardopts` Options File
------------------------

Unless your documentation is very small, you'll end up needing to run `yardoc`
with many options.  The `yardoc` tool will use the options found in this file.
It is recommended to check this in to your repository and distribute it with
your source. This file is placed at the root of your project (in the directory
you run `yardoc` from) and contains all of arguments you would otherwise pass
to the command-line tool. For instance, if you often type:

    yardoc --no-private --protected app/**/*.rb - README LEGAL COPYING
    
You can place the following into your `.yardopts`:

    --no-private --protected app/**/*.rb - README LEGAL COPYING
    
This way, you only need to type:

    yardoc

Any extra switches passed to the command-line now will be appended to your
`.yardopts` options.

Note that options for `yardoc` are discussed in the {file:README.md README}, 
and a full overview of the `.yardopts` file can be found in {YARD::CLI::Yardoc}.

<a name="docing"></a>
Configuring YARD
================

YARD (0.6.2+) supports a global configuration file stored in `~/.yard/config`.
This file is stored as a YAML file and can contain arbitrary keys and values
that can be used by YARD at run-time. YARD defines specific keys that are used
to control various features, and they are listed in {YARD::Config::DEFAULT_CONFIG_OPTIONS}.
A sample configuration file might look like:

    :load_plugins: false
    :ignored_plugins:
      - my_plugin
      - my_other_plugin
    :autoload_plugins:
      - my_autoload_plugin
    :safe_mode: false
    
You can also view and edit these configuration options from the commandline
using the `yard config` command. To list your configuration, use `yard config --list`.
To view a key, use `yard config ITEM`, and to set it, use `yard config ITEM VALUE`.

<a name="extending"></a>
Extending YARD
==============

There are many ways to extend YARD to support non-standard Ruby syntax (DSLs), 
add new meta-data tags or programmatically access the intermediate metadata
and documentation from code. An overview of YARD's full architecture can be
found in the {file:docs/Overview.md} document.

For information on adding support for Ruby DSLs, see the {file:docs/Handlers.md}
and {file:docs/Parser.md} architecture documents.

For information on adding extra tags, see {file:docs/Tags.md}.

For information on accessing the data YARD stores about your documentation,
look at the {file:docs/CodeObjects.md} architecture document.

<a name="templating"></a>
Templating YARD
===============

In many cases you may want to change the style of YARD's templates or add extra
information after extending it. The {file:docs/Templates.md} architecture
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
