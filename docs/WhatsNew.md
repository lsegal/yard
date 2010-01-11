What's New in 0.5.x?
====================

1. **Support for documenting native Ruby C code** (0.5.0)
2. **Incremental parsing and output generation with `yardoc -c`** (0.5.0, 0.5.3)
2. **Improved `yri` support to perform lookups on installed Gems** (0.5.0)
3. **Added `yardoc --default-return` and `yardoc --hide-void-return`** (0.5.0)
4. **Multiple syntax highlighting language support** (0.5.0)
5. **New .yardoc format** (0.5.0)
6. **Support for yard-doc-* gem packages as hosted .yardoc dbs** (0.5.1)
7. **Support for extra search paths in `yri`** (0.5.1)
8. **Generating HTML docs now adds frames view** (0.5.3)
9. **Tree view for class list** (0.5.3)
10. **Ability to specify markup format of extra files** (0.5.3)

Support for documenting native Ruby C code (0.5.0)
--------------------------------------------------

It is now possible to document native Ruby extensions with YARD with a new
C parser mostly borrowed from RDoc. This enables the ability to document
Ruby's core and stdlibs which will be hosted on http://yardoc.org/docs. In
addition, the .yardoc dump for the Ruby-core classes will become available
as an installable gem for yri support (see #3).

Incremental parsing and output generation with `yardoc -c` (0.5.0, 0.5.3)
-------------------------------------------------------------------------

<p class="note">Note: in 0.5.3 and above you must use <tt>--incremental</tt> 
  to incrementally generate HTML, otherwise only parsing will be done 
  incrementally but HTML will be generated with all objects. <tt>--incremental</tt>
  implies <tt>-c</tt>, so no need to specify them both.</p>

YARD now compares file checksums before parsing when using `yardoc -c`
(aka `yardoc --use-cache`) to do incremental parsing of only the files that
have changed. HTML (or other output format) generation will also only be
done on the objects that were parsed from changed files (*). This makes doing
a documentation development cycle much faster for quick HTML previews. Just
remember that when using incremental output generation, the index will not
be rebuilt and inter-file links might not hook up right, so it is best to
perform a full rebuild at the end of such previews.

(*) Only for versions prior to 0.5.3. For 0.5.3+, use `--incremental` for
incremental HTML output.

Improved `yri` support to perform lookups on installed Gems (0.5.0)
-------------------------------------------------------------------

The `yri` executable can now perform lookups on gems that have been parsed
by yard. Therefore, to use this command you must first parse all gems with
YARD. To parse all gems, use the following command:

    $ sudo yardoc --build-gems
    
The above command builds a .yardoc file for all installed gems in the
respective gem directory. If you do not have write access to the gem path,
YARD will write the yardoc file to `~/.yard/gem_index/NAME-VERSION.yardoc`.

Note: you can also use `--re-build-gems` to force re-parsing of all gems.

You can now do lookups with yri:

    $ yri JSON
    
All lookups are cached to `~/.yard/yri_cache` for quicker lookups the second
time onward.

Added `yardoc --default-return` and `yardoc --hide-void-return` (0.5.0)
-----------------------------------------------------------------------

YARD defaults to displaying (Object) as the default return type of any
method that has not declared a @return tag. To customize the default
return type, you can specify:

    $ yardoc --default-return 'MyDefaultType'
    
You can also use the empty string to list no return type.

In addition, you can use --hide-void-return to ignore any method that
defines itself as a void type by: `@return [void]`

Multiple syntax highlighting language support (0.5.0)
-----------------------------------------------------

YARD now supports the ability to specify a language type for code blocks in 
docstrings. Although no actual highlighting support is added for any language
but Ruby, you can add your own support by writing your own helper method:

    # Where LANGNAME is the language:
    def html_syntax_highlight_LANGNAME(source)
      # return highlighted HTML
    end
    
To use this language in code blocks, prefix the block with `!!!LANGNAME`:

    !!!plain
    !!!python
    def python_code(self):
      return self

By the same token. you can now use `!!!plain` to ignore highlighting for
a specific code block.

New .yardoc format (0.5.0)
--------------------------

To make the above yri support possible, the .yardoc format was redesigned
to be a directory instead of a file. YARD can still load old .yardoc files,
but they will be automatically upgraded if re-saved. The new .yardoc format
does have a larger memory footprint, but this will hopefully be optimized
downward.

Support for yard-doc-* gem packages as hosted .yardoc dbs (0.5.1)
-----------------------------------------------------------------

You can now install special YARD plugin gems titled yard-doc-NAME to get
packaged a .yardoc database. This will enable yri lookups or building docs
for the gem without the code. 

One main use for this is the `yard-doc-core` package, which enabled yri 
support for Ruby core classes (stdlib coming soon as `yard-doc-stdlib`).
To install it, simply:

    $ sudo gem install yard-doc-core
    # now you can use:
    $ yri String

This will by default install the 1.9.1 core library. To install a library
for a specific version of Ruby, use the `--version` switch on gem:

    $ sudo gem install --version '= 1.8.6' yard-doc-core

Support for extra search paths in `yri` (0.5.1)
-----------------------------------------------

You can now add custom paths to non-gem .yardoc files 
by adding them as newline separated paths in `~/.yard/yri_search_paths`.

Generating HTML docs now adds frames view (0.5.3)
-------------------------------------------------

`yardoc` will now create a `frames.html` file when generating HTML documents
which allows the user to view documentation inside frames, for those users who
still find frames beneficial.

Tree view for class list (0.5.3)
--------------------------------

The class list now displays as an expandable tree view to better organized an 
otherwise cluttered namespace. If you properly namespace your less important
classes (like Rails timezone classes), they will not take up space in the
class list unless the user looks for them.

Ability to specify markup format of extra files (0.5.3)
-------------------------------------------------------

You can now specify the markup format of an extra file (like README) at the
top of the file with a shebang-like line:

    #!textile
    contents here
    
The above file contents will be rendered with a textile markup engine 
(eg. RedCloth).


What's New in 0.4.x?
====================

1. **New templating engine and templates**
2. **yardoc `--query` argument**
3. **Greatly expanded API documentation**
4. **New plugin support**
5. **New tags (@abstract, @private)**
6. **Default rake task is now `rake yard`**

New templating engine and templates
-----------------------------------

The templates were redesigned, most notably removing the ugly frameset, adding
search to the class/method lists, simplifying the layout and making things 
generally prettier. You should also notice that more tags are now visible in
the templates such as @todo, the new @abstract and @note tags and some others
that existed but were previously omitted from the generated documentation.

There is also a new templating engine (based on the tadpole templating library) 
to allow for much more user customization. You can read about it in 
{file:Templates.md}.

yardoc `--query` argument
-------------------------

The yardoc command-line tool now supports queries to select which classes,
modules or methods to include in documentation based on their data or meta-data.
For instance, you can now generate documentation for your "public" API only by
adding "@api public" to each of your public API methods/classes and using
the following argument:

    --query '@api.text == "public"'
    
More information on queries is in the {file:README.md}.

Greatly expanded API documentation
----------------------------------

Last release focused on many how-to and architecture documents to explain
the design of YARD, but many of the actual API classes/methods were still
left undocumented. This release marks a focus on getting YARD's own documentation
up to par so that it can serve as an official reference on the recommended
conventions to use when documenting code.

New plugin support
------------------

YARD now supports loading of plugins via RubyGems. Any gem named `yard-*` or
`yard_*` will now be loaded when YARD starts up. Note that the '-' separator 
is the recommended naming scheme.

To ignore plugins, add the gem names to `~/.yard/ignored_plugins` on separate
lines (or separated by whitespace).

New tags (@abstract, @private)
------------------------------

Two new tags were added to the list of builtin meta-tags in YARD. `@abstract`
marks a class/module/method as abstract while `@private` marks an object
as "private". The latter tag is unsed in situations where an object is public
due to Ruby's own visibility limitations (constants, classes and modules
can never be private) but not actually part of your public API. You should
use this tag sparingly, as it is not meant to be an equivalent to RDoc's
`:nodoc:` tag. Remember, YARD recommends documenting private objects too.
This tag exists so that you can create a query (`--query !@private`) to
ignore all of these private objects in your documentation. You can also
use the new `--no-private` switch, which is a shortcut to the afformentioned
query. You can read more about the new tags in the {file:GettingStarted.md} 
guide.

Default rake task is now `rake yard`
------------------------------------

Not a big change, but anyone using the default "rake yardoc" task should
update their scripts: 

[http://github.com/lsegal/yard/commit/ad38a68dd73898b06bd5d0a1912b7d815878fae0](http://github.com/lsegal/yard/commit/ad38a68dd73898b06bd5d0a1912b7d815878fae0)


What's New in 0.2.3.x?
======================

1. **Full Ruby 1.9 support**
2. **New parser code and handler API for 1.9**
3. **A new `@overload` tag**
4. **Better documentation**
5. **Template changes and bug fixes**

Full Ruby 1.9 support
---------------------

YARD's development actually focuses primarily on 1.9 from the get-go, so it is 
not an afterthought. All features are first implemented for compatibility with 
1.9, but of course all functionality is also tested in 1.8.x. YARD 0.2.2 was
mostly compatible with 1.9, but the new release improves and extends in certain
areas where compatibility was lacking. The new release should be fully functional
in Ruby 1.9.
  
New parser code and handler API for 1.9
---------------------------------------

Using Ruby 1.9 also gives YARD the advantage of using the new `ripper` library 
which was added to stdlib. The ripper parser is Ruby's official answer to 
projects like ParseTree and ruby2ruby. Ripper allows access to the AST as it 
is parsed by the Ruby compiler. This has some large benefits over alternative 
projects: 

  1. It is officially supported and maintained by the Ruby core team.
  2. The AST is generated directly from the exact same code that drives the
     compiler, meaning anything that compiles is guaranteed to generate the
     equivalent AST.
  3. It needs no hacks, gems or extra libs and works out of the box in 1.9.
  4. It's *fast*.
  
Having the AST means that developers looking to extend YARD have much better
access to the parsed code than in previous versions. The only caveat is that
this library is not back-compatible to 1.8.x. Because of this, there are
subtle changes to the handler extension API that developers use to extend YARD.
Namely, there is now a standard API for 1.9 and a "legacy" API that can run in
both 1.8.x and 1.9 if needed. A developer can still use the legacy API to write
handlers that are compatible for both 1.8.x and 1.9 in one shot, or decide to
implement the handler using both APIs. Realize that the benefit of using the new
API means 1.9 users will get a 2.5x parsing speed increase over running the legacy
handlers (this is *in addition to* the ~1.8x speed increase of using YARV over MRI).
    
A new `@overload` tag
---------------------

The new `@overload` tag enables users to document methods that take multiple 
parameters depending on context. This is basically equivalent to RDoc's call-seq,
but with a name that is more akin to the OOP concept of method overloading
that is actually being employed. Here's an example:

      # @overload def to_html(html, autolink = true)
      #   This docstring describes the specific overload only.
      #   @param [String] html the HTML
      #   @param [Boolean] autolink whether or not to atuomatically link
      #     URL references
      # @overload def to_html(html, opts = {})
      #   @param [String] html the HTML
      #   @param [Hash] opts any attributes to add to the root HTML node
      def to_html(*args)
        # split args depending on context
      end
      
As you can see each overload takes its own nested tags (including a docstring)
as if it were its own method. This allows "virtual" overloading behaviour at
the API level to make Ruby look like overload-aware languages without caring
about the implementation details required to add the behaviour.

It is still recommended practice, however, to stay away from overloading when
possible and document the types of each method's real parameters. This allows
toolkits making use of YARD to get accurate type information for your methods,
for instance, allowing IDE autocompletion. There are, of course, situations
where overload just makes more sense.

Better documentation
--------------------

The first few iterations of YARD were very much a proof of concept. Few people
were paying attention and it was really just pieced together to see what was
feasible. Now that YARD is gaining interest, there are many developers that
want to take advantage of its extensibility support to do some really cool stuff.
Considerable time was spent for this release documenting, at a high level, what
YARD can do and how it can be done. Expect this documentation to be extended and
improved in future releases.

Template changes and bug fixes
------------------------------

Of course no new release would be complete without fixing the old broken code.
Some tags existed but were not present in generated documentation. The templates
were mostly fixed to add the major omitted tags. In addition to template adjustments,
many parsing bugs were ironed out to make YARD much more stable with existing projects
(Rails, HAML, Sinatra, Ramaze, etc.).
