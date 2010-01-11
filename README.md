YARD Release 0.5.3 "The Longest" (Jan 11th 2010)
================================================

**Homepage**:  [http://yardoc.org](http://yardoc.org)   
**IRC**:       **Join us on IRC in #yard on irc.freenode.net!**   
**Git**:       [http://github.com/lsegal/yard](http://github.com/lsegal/yard)   
**Author**:    Loren Segal   
**Copyright**: 2007-2009    
**License**:   MIT License


SYNOPSIS
--------

YARD is a documentation generation tool for the Ruby programming language. 
It enables the user to generate consistent, usable documentation that can be 
exported to a number of formats very easily, and also supports extending for 
custom Ruby constructs such as custom class level definitions. Below is a 
summary of some of YARD's notable features.


FEATURE LIST
------------
                                                                              
**1. RDoc/SimpleMarkup Formatting Compatibility**: YARD is made to be compatible 
with RDoc formatting. In fact, YARD does no processing on RDoc documentation 
strings, and leaves this up to the output generation tool to decide how to 
render the documentation. 

**2. Yardoc Meta-tag Formatting Like Python, Java, Objective-C and other languages**: 
YARD uses a '@tag' style definition syntax for meta tags alongside  regular code 
documentation. These tags should be able to happily sit side by side RDoc formatted 
documentation, but provide a much more consistent and usable way to describe 
important information about objects, such as what parameters they take and what types
they are expected to be, what type a method should return, what exceptions it can 
raise, if it is deprecated, etc.. It also allows information to be better (and more 
consistently) organized during the output generation phase. You can find a list
of tags in the {file:GettingStarted.md#taglist GettingStarted.md} file.

YARD also supports an optional "types" declarations for certain tags. 
This allows the developer to document type signatures for ruby methods and 
parameters in a non intrusive but helpful and consistent manner. Instead of 
describing this data in the body of the description, a developer may formally 
declare the parameter or return type(s) in a single line. Consider the 
following Yardoc'd method: 

     ## 
     # Reverses the contents of a String or IO object. 
     # 
     # @param [String, #read] contents the contents to reverse 
     # @return [String] the contents reversed lexically 
     def reverse(contents) 
       contents = contents.read if respond_to? :read 
       contents.reverse 
     end
                                                                     
With the above @param tag, we learn that the contents parameter can either be
a String or any object that responds to the 'read' method, which is more 
powerful than the textual description, which says it should be an IO object. 
This also informs the developer that they should expect to receive a String 
object returned by the method, and although this may be obvious for a 
'reverse' method, it becomes very useful when the method name may not be as 
descriptive. 
                                                                              
**3. Custom Constructs and Extensibility of YARD**: Take for instance the example: 
   
    class A 
      class << self 
        def define_name(name, value) 
          class_eval "def #{name}; #{value.inspect} end" 
        end 
      end 
 
      # Documentation string for this name 
      define_name :publisher, "O'Reilly"
    end
                                                                        
This custom declaration provides dynamically generated code that is hard for a
documentation tool to properly document without help from the developer. To 
ease the pains of manually documenting the procedure, YARD can be extended by 
the developer to handled the `define_name` construct and add the required 
method to the defined methods of the class with its documentation. This makes 
documenting external API's, especially dynamic ones, a lot more consistent for
consumption by the users. 
                                                                              
**4. Raw Data Output**: YARD also outputs documented objects as raw data (the 
dumped Namespace) which can be reloaded to do generation at a later date, or 
even auditing on code. This means that any developer can use the raw data to 
perform output generation for any custom format, such as YAML, for instance. 
While YARD plans to support XHTML style documentation output as well as 
command line (text based) and possibly XML, this may still be useful for those
who would like to reap the benefits of YARD's processing in other forms, such 
as throwing all the documentation into a database. Another useful way of 
exploiting this raw data format would be to write tools that can auto generate
test cases, for example, or show possible unhandled exceptions in code. 
                                                                              

USAGE
-----

There are a couple of ways to use YARD. The first is via command-line, and the
second is the Rake task. There are also the `yard-graph` and `yri` binaries to
look at, if you want to poke around.

**1. yardoc Command-line Tool**

The most obvious way to run YARD is to run the `yardoc` binary file that comes
with YARD. This will, among other things, generate the HTML documentation for
your project code. You can type `yardoc --help` to see the options
that YARD provides, but the easiest way to generate docs for your code is to
simply type `yardoc` in your project root. This will assume your files are
located in the `lib/` directory. If they are located elsewhere, you can specify
paths and globs from the commandline via:

    $ yardoc 'lib/**/*.rb' 'app/**/*.rb' ...etc...

The tool will generate a `.yardoc` file which will store the cached database
of your source code and documentation. If you want to re-generate your docs
with another template you can simply use the `--use-cache` (or -c) 
option to speed up the generation process by skipping source parsing.

YARD will by default only document code in your public visibility. You can
document your protected and private code by adding `--protected` or
`--private` to the option switches. In addition, you can add `--no-private`
to also ignore any object that has the `@private` meta-tag. This is similar
to RDoc's ":nodoc:" behaviour, though the distinction is important. RDoc
implies that the object with :nodoc: would not be documented, whereas
YARD still recommends documenting private objects for the private API (for
maintainer/developer consumption).

You can also add extra informative files (README, LICENSE) by separating
the globs and the filenames with '-'.

    $ yardoc 'app/**/*.rb' - README LICENSE FAQ
    
If no globs preceed the '-' argument, the default glob (lib/**/*.rb) is
used:

    $ yardoc - README LICENSE FAQ

Note that the README file can be specified with its own `--readme` switch.

You can also add a `.yardopts` file to your project directory which lists
the switches separated by whitespace (newlines or space) to pass to yardoc 
whenever it is run.

<h4>Queries</h4>

The `yardoc` tool also supports a `--query` argument to only include objects
that match a certain data or meta-data query. The query syntax is Ruby, though
a few shortcuts are available. For instance, to document only objects that have
an "@api" tag with the value "public", all of the following syntaxes would give
the same result:

    --query '@api.text == "public"'
    --query 'object.has_tag?(:api) && object.tag(:api).text == "public"'
    --query 'has_tag?(:api) && tag(:api).text == "public"'

Note that the "@tag" syntax returns the first tag named "tag" on the object. 
To return the array of all tags named "tag", use "@@tag".
    
Multiple `--query` arguments are allowed in the command line parameters. The
following two lines both check for the existence of a return and param tag:

    --query '@return' --query '@param'
    --query '@rturn && @param'
    
For more information about the query syntax, see the {YARD::Verifier} class.

**2. Rake Task**

The second most obvious is to generate docs via a Rake task. You can do this by 
adding the following to your `Rakefile`:

    YARD::Rake::YardocTask.new do |t|
      t.files   = ['lib/**/*.rb', OTHER_PATHS]   # optional
      t.options = ['--any', '--extra', '--opts'] # optional
    end

both the `files` and `options` settings are optional. `files` will default to
`lib/**/*.rb` and `options` will represents any options you might want
to add. Again, a full list of options is available by typing `yardoc --help`
in a shell. You can also override the options at the Rake command-line with the
OPTS environment variable:

    $ rake yard OPTS='--any --extra --opts'
                                                                              
**3. `yri` RI Implementation**

The yri binary will use the cached .yardoc database to give you quick ri-style
access to your documentation. It's way faster than ri but currently does not
work with the stdlib or core Ruby libraries, only the active project. Example:

    $ yri YARD::Handlers::Base#register
    $ yri File.relative_path
    
Note that class methods must not be referred to with the "::" namespace 
separator. Only modules, classes and constants should use "::".

You can also do lookups on any installed gems. Just make sure to build the
.yardoc databases for installed gems with:

    $ sudo yardoc --build-gems
    
If you don't have sudo access, it will write these files to your `~/.yard`
directory. `yri` will also cache lookups there.

**4. `yard-graph` Graphviz Generator**

You can use `yard-graph` to generate dot graphs of your code. This, of course,
requires [Graphviz](http://www.graphviz.org) and the `dot` binary. By default
this will generate a graph of the classes and modules in the best UML2 notation
that Graphviz can support, but without any methods listed. With the `--full`
option, methods and attributes will be listed. There is also a `--dependencies`
option to show mixin inclusions. You can output to stdout or a file, or pipe directly
to `dot`. The same public, protected and private visibility rules apply to yard-graph.
More options can be seen by typing `yard-graph --help`, but here is an example:

    $ yard-graph --protected --full --dependencies


CHANGELOG
---------

- **January.11.10**: 0.5.3 release
    - See {file:docs/WhatsNew.md what's new document} for changes

- **December.16.09**: 0.5.2 release
    - See {file:docs/WhatsNew.md what's new document} for changes

- **December.15.09**: 0.5.1 release
    - See {file:docs/WhatsNew.md what's new document} for changes

- **December.13.09**: 0.5.0 release
    - See {file:docs/WhatsNew.md what's new document} for changes

- **November.15.09**: 0.4.0 release
    - Added new templating engine based on [tadpole](http://github.com/lsegal/tadpole)
    - Added YARD queries (`--query` CLI argument to yardoc)
    - Greatly expanded YARD documentation
    - Added plugin support
    - New `@abstract` and `@private` tags
    - Changed default rake task to `rake yard`
    - Read about changes in {file:WhatsNew.md}

- **August.13.09**: 0.2.3.5 release
    - Minor bug fixes.

- **August.07.09**: 0.2.3.4 release
    - Minor bug fixes.

- **July.26.09**: 0.2.3.3 release
    - Minor bug fixes.

- **July.06.09**: 0.2.3.2 release
    - Fix Textile hard-break issues
    - Add description for @see tag to use as link title in HTML docs.
    - Add --title CLI option to specify a title for HTML doc files.
    - Add custom.css file that can be overridden with various custom
      styelsheet declarations. To use this, simply add `default/fulldoc/html/custom.css`
      inside your code directory and use the `-t` template directory yardoc CLI
      option to point to that template directory (the dir holding 'default').
    - Add support in `yardoc` CLI to specify extra files (formerly --files)
      by appending "- extra files here" after regular source files. Example:

            yardoc --private lib/**/*.rb - FAQ LICENSE

- **Jun.13.09**: 0.2.3.1 release.
    - Add a RubyGems 1.3.2+ plugin to generate YARD documentation instead of
      RDoc. To take advantage of this plugin, set `has_rdoc = 'yard'` in your
      .gemspec file.

- **Jun.07.09**: 0.2.3 release. See the {file:WhatsNew.md} file for a 
  list of important new features.

- **Jun.16.08**: 0.2.2 release. This is the largest changset since yard's 
  conception and involves a complete overhaul of the parser and API to make it
  more robust and far easier to extend and use for the developer.

- **Feb.20.08**: 0.2.1 release. 

- **Feb.24.07**: Released 0.1a experimental version for testing. The goal here is
  to get people testing YARD on their code because there are too many possible  
  code styles to fit into a sane amount of test cases. It also demonstrates the 
  power of YARD and what to expect from the syntax (Yardoc style meta tags).    
                                                          

COPYRIGHT
---------

YARD &copy; 2007-2009 by [Loren Segal](mailto:lsegal@soen.ca). Licensed under the MIT 
license. Please see the {file:LICENSE} for more information.
