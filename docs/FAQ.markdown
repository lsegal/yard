FAQ
===

(1) So, show me some cool stuff. What can YARD do?
--------------------------------------------------

- [Visualize with GraphViz][graphviz] Visualize your classes and methods with GraphViz
- [Inline RSpecs][inline-rspecs] In your rspec files, call the following to refer 
  back to and call the inline rspecs: `described_in_docs "String", "camelcase"`
- [Inline doc testing][inline-doctest] Use the 'docspec' command line tool to 
  run the above tests.  This is similar to [Ruby DocTest][rubydoctest]'s inline 
  irb testing.
  
(2) Why did you pick the @-symbol tags for documentation?
---------------------------------------------------------
Java, C++, Python and many other languages have standard documentation tools 
that use the @tag "standard".  This has been extended to the Ruby language, 
and YARD takes advantage of this common style.

(3) Can I tweak it to use some other documentation standard?
------------------------------------------------------------
  Yes. YARD is flexible enough to have other documentation syntaxes put into use. [TODO: Add information about customization here.]

(4) Why don't you use ParseTree, or sydparse?  Why did you write your own parser?
---------------------------------------------------------------------------------
As of Ruby 1.9, YARD uses Ripper parser which is packaged with the standard library
and maintained as such. The legacy parser is only being maintained for bug fixes, 
but was written because no existing parser properly supported putting comments 
into the parse tree and did not robustly support edge case scenarios.

[graphviz]:http://gnuu.org/2008/02/29/generating-class-diagrams-with-yard-and-graphviz/
[inline-rspecs]:http://github.com/lsegal/yard/tree/5b07d706eee6bc0d7f13d9ec1e6e0ab914d3679c/lib/yard/core_ext/string.rb
[inline-doctest]:http://github.com/lsegal/yard/tree/master/lib/yard/handlers/base.rb#L350
[rubydoctest]:http://github.com/tablatom/rubydoctest