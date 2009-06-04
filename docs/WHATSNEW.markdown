YARD: What's New in 0.2.3?
==========================

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
