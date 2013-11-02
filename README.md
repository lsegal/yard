# YARD: Yay! A Ruby Documentation Tool

**Homepage**:     http://yardoc.org   
**IRC**:          [irc.freenode.net / #yard](irc://irc.freenode.net/yard)    
**Git**:          http://github.com/lsegal/yard   
**Author**:       Loren Segal  
**Contributors**: http://github.com/lsegal/yard/contributors    
**Copyright**:    2007-2013    
**License**:      MIT License    
**Latest Version**: 0.8.7.3    
**Release Date**: November 1st 2013    

## Synopsis

YARD is a documentation generation tool for the Ruby programming language.
It enables the user to generate consistent, usable documentation that can be
exported to a number of formats very easily, and also supports extending for
custom Ruby constructs such as custom class level definitions. Below is a
summary of some of YARD's notable features.


## Feature List

**1. RDoc/SimpleMarkup Formatting Compatibility**: YARD is made to be compatible
with RDoc formatting. In fact, YARD does no processing on RDoc documentation
strings, and leaves this up to the output generation tool to decide how to
render the documentation.

**2. Yardoc Meta-tag Formatting Like Python, Java, Objective-C and other languages**:
YARD uses a '@tag' style definition syntax for meta tags alongside  regular code
documentation. These tags should be able to happily sit side by side RDoc formatted
documentation, but provide a much more consistent and usable way to describe
important information about objects, such as what parameters they take and what types
they are expected to be, what type a method should return, what exceptions it can
raise, if it is deprecated, etc.. It also allows information to be better (and more
consistently) organized during the output generation phase. You can find a list
of tags in the {file:docs/Tags.md#taglist Tags.md} file.

YARD also supports an optional "types" declarations for certain tags.
This allows the developer to document type signatures for ruby methods and
parameters in a non intrusive but helpful and consistent manner. Instead of
describing this data in the body of the description, a developer may formally
declare the parameter or return type(s) in a single line. Consider the
following method documented with YARD formatting:

     # Reverses the contents of a String or IO object.
     #
     # @param [String, #read] contents the contents to reverse
     # @return [String] the contents reversed lexically
     def reverse(contents)
       contents = contents.read if contents.respond_to? :read
       contents.reverse
     end

With the above @param tag, we learn that the contents parameter can either be
a String or any object that responds to the 'read' method, which is more
powerful than the textual description, which says it should be an IO object.
This also informs the developer that they should expect to receive a String
object returned by the method, and although this may be obvious for a
'reverse' method, it becomes very useful when the method name may not be as
descriptive.

**3. Custom Constructs and Extensibility of YARD**: YARD is designed to be
extended and customized by plugins. Take for instance the scenario where you
need to document the following code:

    class List
      # Sets the publisher name for the list.
      cattr_accessor :publisher
    end

This custom declaration provides dynamically generated code that is hard for a
documentation tool to properly document without help from the developer. To
ease the pains of manually documenting the procedure, YARD can be extended by
the developer to handle the `cattr_accessor` construct and automatically create
an attribute on the class with the associated documentation. This makes
documenting external API's, especially dynamic ones, a lot more consistent for
consumption by the users.

YARD is also designed for extensibility everywhere else, allowing you to add
support for new programming languages, new data structures and even where/how
data is stored.

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

**5. Local Documentation Server**: YARD can serve documentation for projects
or installed gems (similar to `gem server`) with the added benefit of dynamic
searching, as well as live reloading. Using the live reload feature, you can
document your code and immediately preview the results by refreshing the page;
YARD will do all the work in re-generating the HTML. This makes writing
documentation a much faster process.


## Installing

To install YARD, use the following command:

    $ gem install yard

(Add `sudo` if you're installing under a POSIX system as root)

Alternatively, if you've checked the source out directly, you can call
`rake install` from the root project directory.

**Important Note for Debian/Ubuntu users:** there's a possible chance your Ruby
install lacks RDoc, which is occasionally used by YARD to convert markup to HTML.
If running `which rdoc` turns up empty, install RDoc by issuing:

    $ sudo apt-get install rdoc


## Usage

There are a couple of ways to use YARD. The first is via command-line, and the
second is the Rake task.

**1. yard Command-line Tool**

YARD comes packaged with a executable named `yard` which can control the many
functions of YARD, including generating documentation, graphs running the
YARD server, and so on. To view a list of available YARD commands, type:

    $ yard --help

Plugins can also add commands to the `yard` executable to provide extra
functionality.

### Generating Documentation

<span class="note">The `yardoc` executable is a shortcut for `yard doc`.</span>

The most common command you will probably use is `yard doc`, or `yardoc`. You
can type `yardoc --help` to see the options that YARD provides, but the
easiest way to generate docs for your code is to simply type `yardoc` in your
project root. This will assume your files are
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

If no globs precede the '-' argument, the default glob (`lib/**/*.rb`) is
used:

    $ yardoc - README LICENSE FAQ

Note that the README file can be specified with its own `--readme` switch.

You can also add a `.yardopts` file to your project directory which lists
the switches separated by whitespace (newlines or space) to pass to yardoc
whenever it is run. A full overview of the `.yardopts` file can be found in
{YARD::CLI::Yardoc}.

### Queries

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
    --query '@return && @param'

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

    $ sudo yard gems

If you don't have sudo access, it will write these files to your `~/.yard`
directory. `yri` will also cache lookups there.

**4. `yard server` Documentation Server**

The `yard server` command serves documentation for a local project or all installed
RubyGems. To serve documentation for a project you are working on, simply run:

    $ yard server

And the project inside the current directory will be parsed (if the source has
not yet been scanned by YARD) and served at [http://localhost:8808](http://localhost:8808).

### Live Reloading

If you want to serve documentation on a project while you document it so that
you can preview the results, simply pass `--reload` (`-r`) to the above command
and YARD will reload any changed files on each request. This will allow you to
change any documentation in the source and refresh to see the new contents.

### Serving Gems

To serve documentation for all installed gems, call:

    $ yard server --gems

This will also automatically build documentation for any gems that have not
been previously scanned. Note that in this case there will be a slight delay
between the first request of a newly parsed gem.


**5. `yard graph` Graphviz Generator**

You can use `yard graph` to generate dot graphs of your code. This, of course,
requires [Graphviz](http://www.graphviz.org) and the `dot` binary. By default
this will generate a graph of the classes and modules in the best UML2 notation
that Graphviz can support, but without any methods listed. With the `--full`
option, methods and attributes will be listed. There is also a `--dependencies`
option to show mixin inclusions. You can output to stdout or a file, or pipe directly
to `dot`. The same public, protected and private visibility rules apply to `yard graph`.
More options can be seen by typing `yard graph --help`, but here is an example:

    $ yard graph --protected --full --dependencies


## Changelog

- **November.1.13**: 0.8.7.3 release
    - Handle Unicode method/class/file names in server URL encoding (lsegal/rubydoc.info#69).
    - Style keyword style hashes with same symbol color in code highlighting (#707).
    - Fix broken JS when visiting docs in file:// scheme (#706).
    - Add support for new AsciiDoc file extensions (#704).
    - Fix issues where non-Ruby code blocks would not display in Ruby 2 (#702).
    - Add support for extra Ruby 2 symbol types in Ripper (#701).
    - Ensure config directory exists before saving config file (#700).

- **September.18.13**: 0.8.7.2 release
    - Disallow absolute URLs when using frame anchor support.
    - Support casted functions in CRuby method declarations (#697)

- **September.11.13**: 0.8.7.1 release
    - Fix potential XSS issue with frame anchor support.
    - Add support for gettext 3.x gem.

- **July.26.13**: 0.8.7 release
    - Added `--hide-api API` option to hide objects with a given `@api` tag (#685).
    - Added "Returns ...." prefix to summary when a lone @return tag is used.
    - Fixed issue that caused ref tags to be added to a docstring twice (#678).
    - Fixed formatting issue in docstring summaries (#686)

- **June.27.13**: 0.8.6.2 release
    - Fixed issue where `yard graph` was not displaying methods

- **April.14.13**: 0.8.6.1 release
    - Fixed broken links in File menu on default HTML template
    - Added --layout switch to `yard display` to wrap output in layout template.
    - See {file:docs/WhatsNew.md} for more information on added features.

- **April.13.13**: 0.8.6 release
    - Various fixes and improved Ruby 2.x compatibility support
    - Added support for `asciidoc` markup type
    - Added `yard markups` command to list available markup types
    - Added `yard display` command to display and format an individual object
    - See {file:docs/WhatsNew.md} for more information on added features.

- **February.26.13**: 0.8.5.2 release
    - Support new keyword argument syntax in method signatures (Ruby 2.x)

- **February.25.13**: 0.8.5.1 release
    - Fix `yard diff` of gem files with RubyGems 2.x

- **February.24.13**: 0.8.5 release
    - Basic support for Ruby 2.0 (fix compat issues in RDoc 4.0, RubyGems 2.0)
    - Add CSS styling for tables in default HTML template

- **February.5.13**: 0.8.4.1 release
    - Fix regression that broke loading of existing yardoc dbs (#648)

- **February.4.13**: 0.8.4 release
    - Add `-B/--bind` switch to yard server (#593, #608)
    - Add CodeObjects::Base#title for plugins to customize how object
      links display (#646)
    - Disable linking objects filtered out by verifiers (#645)
    - Allow macro expansion on class methods (#632)
    - Expand newly attached macro on first DSL method call (#631)
    - Disable RubyGems plugin in Ruby 2.0 (#627)
    - Fix line range for class/module node bodies (#626)
    - Search extended modules for attached DSL macros (#553)

- **October.14.12**: 0.8.3 release
    - Add `--non-transitive-tag` to disable tag transitivity (#571)
    - Support --db inside .yardopts for graph/server commands (#583, #586)
    - Fix handling for =begin/=end docstrings (#577, #578)
    - Parser only sorts file lists when a glob is provided (#572)
    - Fix formatting in `{include:Object#method}` syntax (#569)
    - Fix @option tag inside of module functions (#563)
    - Fix to `--api` and `--no-api` support (#559)
    - Fix class nesting issues when path starts with "::" (#552)

- **June.9.12**: 0.8.2.1 release
    - Fix a set of regressions in yard server search and dynamic generation

- **June.7.12**: 0.8.2 release
    - Added progress style output in tty terminals
    - Embedded mixins should ignore methods defined on module (#539)
    - Fixed permalinks for embedded mixins in `yard server` (#540)
    - Improve parsing in CRuby code (#543)
    - Ensure Registry.resolve picks module when parsing mixins (#545)
    - Fixed regression that caused various commands to not show output (#548)
    - Respect current visibility when parsing class conditions (#551)

- **May.2.12**: 0.8.1 release
    - Added `--[no-]api` switch to generate docs for API sets (see {file:docs/WhatsNew.md} for details) (#532)
    - The `yard list` command now uses cache by default (#533)
    - Fix `yardoc` generating incorrectly named method list file (#528)
    - Fix HTML output occasionally showing trailing mdash on options list (#522)

- **April.30.12**: 0.8.0 release
    - See {file:docs/WhatsNew.md} for a list of added features
    - Over 20 bug fixes:
      - Properly filter hidden setter/getter attributes (#394)
      - Fix test failures in Linux environments (#397, #472, #473, #512, #513)
      - Fix attribute inheritance and @private (#432)
      - Fix attribute parsing (#435)
      - Allow aliases for attributes (#436)
      - Fix namespace fetching in `handle_alias()` (#437)
      - Fix overwritten attributes marked as inherited (#442)
      - Fix documenting constants defined from C code with `rb_define_const()` (#443)
      - Do not escape snippets twice (#445)
      - Ajax method/class search should not fire when a non-printable character is pressed (#446)
      - Fix yard server crashing when RDoc is not installed (#456)
      - Fix tags ignored when `(see #foo)` is used (#457)
      - Fix three "Returns" for two `@overload` tags (#458)
      - Do not auto-detect DSL methods as method objects if parameter name is not a valid method name (#464)
      - Fix attaching of macros to Object (#465)
      - Fix handling of `%w()` source in `[]/[]=` parsed context. (#461, pull in #468)
      - Don't add default `@return` if `@overload` has `@return`. (#458, pull in #469)
      - Don't discard tags by (see ...). (#457, pull in #470)
      - Fix constants listed as inherited when overwritten (#474)
      - Fix `yardoc --asset` behaving differently on first and subsequent calls. (#477)
      - `!!!lang` code blocks should set the lang in `<pre>`'s class. (#478, #479)
      - Fix "File List" search tab error. (#502)
      - Fix search bar not redirecting to method page. (#509)
      - Fix server returning exception message bodies as String (#518)

- **January.31.12**: 0.7.5 release
    - Various minor bug fixes

- **December.2.11**: 0.7.4 release
    - Redcarpet is now the default Markdown formatting library. GFM now works out-of-box (#404)
    - Fix server side searching for elements that are marked private (#420)
    - Add 'textile_strict' and 'pre' markup types, reorganize text and none (#416)
    - Improve encoding line detection (#415)
    - Add support for `rb_define_alias` in CRuby code (#413)
    - Fix rendering of some keywords in source view (#410)
    - Add support for RDoc 3.10+ (#406, #407)
    - Fix typewriter text being processed in code blocks (#403)
    - Improve support for has_rdoc in RubyGems 1.8.x (#401)
    - See the {file:docs/WhatsNew.md} document for details on added features

- **October.15.11**: 0.7.3 release
    - Improve support for parsing under Ruby 1.9.2p290 and 1.9.3 (#365, #370)
    - Add support for SWIG generated CRuby code (#369)
    - Add support for `rb_define_attr` calls in CRuby code (#362)
    - Handle file pointers in CRuby code (#358)

- **June.14.11**: 0.7.2 release
    - Fix `yard --help` not showing proper output
    - YARD now expands path to `.yardoc` file in daemon mode for server (#328)
    - Fix `@overload` tag linking to wrong method (#330)
    - Fix incorrect return type when using `@macro` (#334)
    - YARD now requires 'thread' to support RubyGems 1.7+ (#338)
    - Fix bug in constant documentation when using `%w()` (#348)
    - Fix YARD style URL links when using autolinking markdown (#353)

- **May.18.11**: 0.7.1 release
    - Fixes a bug in `yard server` not displaying class list properly.

- **May.17.11**: 0.7.0 release
    - See the {file:docs/WhatsNew.md} document for details on added features
    - Make sure that Docstring#line_range is filled when possible (#243)
    - Set #verifier in YardocTask (#282)
    - Parse BOM in UTF-8 files (#288)
    - Fix instance attributes not showing up in method list (#302)
    - Fix rendering of %w() literals in constants (#306)
    - Ignore keyboard shortcuts when an input is active (#312)
    - And more...

- **April.14.11**: 0.6.8 release
    - Fix regression in RDoc 1.x markup loading
    - Fix regression in loading of markup libraries for `yard server`

- **April.6.11**: 0.6.7 release
    - Fix has_rdoc gem specification issue with new RubyGems plugin API (oops!)

- **April.6.11**: 0.6.6 release
    - Fix error message when RDoc is not present (#270)
    - Add markup type 'none' to perform basic HTML translation (fallback when RDoc is not present)
    - Add support for RubyGems 1.7.x (#272)
    - Fix rendering of `{url description}` syntax when description contains newline

- **March.13.11**: 0.6.5 release
    - Support `ripper` gem in Ruby 1.8.7
    - Upgrade jQuery to 1.5.1
    - Fix handling of alias statements with quoted symbols (#262)
    - Add CSS styles (#260)
    - Unhandled exception in YARD::Handlers::Ruby::MixinHandler indexing documentation for eventmachine (#248)
    - Splice any alias references on method re-definitions into separate methods (#247)
    - Fix "yard graph" (#245)
    - Don't process ++ typewriter text inside of HTML attributes (#244)
    - Prioritize loading of Kramdown before Maruku (#241)
    - Skip shebang encoding in docstrings (#238)
    - Fix truncation of references in @deprecated (#232)
    - Show @api private note when no other tags are present (#231)
    - Detect docstrings starting with "##" as `Docstring#hash_flag` (#230)
    - Remove trailing whitespace from freeform tags (#229)
    - Fix line through for deprecated methods (#225)
    - Mistake in Tags.md (#223)
    - Improve database storage by being more efficient with filesystem usage (#222)
    - Make Registry thread local (#221)
    - Support `private_constant` class method for 1.9.3 (#219)
    - Do not assume RDoc is installed (#214)

- **December.21.10**: 0.6.4 release
    - Fix yri tool crashing with new Config class (gh-217)
    - Fix support for ::TopLevelConstants (gh-216)
    - YARD's test suite is now RSpec2 compatible (gh-215)
    - Improved documentation for YARD::Server features (gh-207)
    - Fix displaying of collaped method summary lists (gh-204)
    - Fix automatic loading of markup providers (gh-206)
    - Fix keyboard shortcuts for Chrome (gh-203)
    - Disallow `extend self` inside of a class (gh-202)
    - Constants now recognized in C extensions (gh-201)

- **November.21.10**: 0.6.3 release
    - Fixed regression that caused `yardoc --markup` to silently exit

- **November.15.10**: 0.6.2 release
    - **Plugins no longer automatically load, use `--plugin` to load a plugin**
    - Added YARD::Config and ~/.yard/config YAML configuration file
    - Added `yard config` command to view/edit YARD configuration file
    - Fixes for YARD in 1.8.6 (gh-178)
    - Various HTML template adjustments and fixes (gh-198,199,200)
    - Improved `yard server -m` multi-project stability (gh-193)
    - Fixed handling of `yardoc --no-private` with missing class definitions (gh-197)
    - Added support for constants defined in C extensions (gh-177)
    - Added support for Structs defined as "Klass = Struct.new(...)" (gh-187)
    - Improved parsing support for third-party gems (gh-174,180)
    - Improved support for JRuby 1.6.4+. YARD now passes all specs in JRuby (gh-185)
    - Improved YARD documentation (gh-172,191,196)

- **September.06.10**: 0.6.1 release
    - Fixed TOC showing on top of class/method list in no-frames view
    - A message now displays when running `yard server` with Rack/Mongrel installed
    - Improved performance of JS inline search for large class/method lists
    - Improved link titles for relative object links
    - Removed `String#camelcase` and `String#underscore` for better Rails compat.
    - Fixed support for loading .yardoc files under Windows
    - Fixed inheritance tree arrows not displaying in certain environments

- **August.29.10**: 0.6.0 release
    - Added dynamic local documentation server
    - Added @group/@endgroup declarations to organize methods into groups
    - Added `yard` executable to serve as main CLI tool with pluggable commands
    - Added `--asset` switch to `yardoc` to copy files/dirs to output dir
    - Added ability to register/manipulate tags via CLI (`--tag`, etc.)
    - Added `yard diff` command
    - Added statistics to `yardoc` output (and `yard stats` command)
    - Added Javascript generated Table of Contents to file pages
    - Updated various APIs
    - Removed `yard-graph` executable
    - See more changes in the {file:docs/WhatsNew.md what's new document}

- **June.22.10**: 0.5.8 release
    - Merge fix from 0.6 branch for --no-private visibility checking

- **June.21.10**: 0.5.7 release
    - Fixed visibility flag parsing in `yardoc`
    - Updated Parser Architecture documentation with new SourceParser API
    - Improved Registry documentation for new load commands
    - Fix loading of .yardoc file as cache (and preserving aliases)
    - Fix "lib" directory missing when running YARD on installed gems

- **June.12.10**: 0.5.6 release
    - Bug fixes for RubyGems plugin, `has_rdoc=false` should now work
    - New API for registering custom parsers. See {file:docs/WhatsNew.md}

- **May.22.10**: 0.5.5 release
    - Various bug fixes

- **March.22.10**: 0.5.4 release
    - See {file:docs/WhatsNew.md what's new document} for changes

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
    - Read about changes in {file:docs/WhatsNew.md}

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

- **Jun.07.09**: 0.2.3 release. See the {file:docs/WhatsNew.md} file for a
  list of important new features.

- **Jun.16.08**: 0.2.2 release. This is the largest changset since yard's
  conception and involves a complete overhaul of the parser and API to make it
  more robust and far easier to extend and use for the developer.

- **Feb.20.08**: 0.2.1 release.

- **Feb.24.07**: Released 0.1a experimental version for testing. The goal here is
  to get people testing YARD on their code because there are too many possible
  code styles to fit into a sane amount of test cases. It also demonstrates the
  power of YARD and what to expect from the syntax (Yardoc style meta tags).


## Copyright

YARD &copy; 2007-2013 by [Loren Segal](mailto:lsegal@soen.ca). YARD is
licensed under the MIT license except for some files which come from the
RDoc/Ruby distributions. Please see the {file:LICENSE} and {file:LEGAL}
documents for more information.
