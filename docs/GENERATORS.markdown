Generators Architecture
=======================

Note: This document describes the architecture of the current generators 
implementation which is likely to undergo large changes in the 0.2.4
release. Keep this in mind if you plan on extending or implementing
custom generators.
      
Generators are the main component in the output generation process of YARD,
which is invoked when conventional HTML/text output needs to be generated
for a set of code objects.

Design Goals
------------

The general design attempts to be as abstracted from actual content and templates
as possible. Unlike RDoc which uses one file to describe the entire template,
YARD splits up the generation of code objects into small components, allowing
template modification for smaller subsets of a full template without having to
duplicate the entire template itself. This is necessary because of YARD's support
for plugins. YARD is designed for extensibility by external plugins, and because
of this, no one plugin can be responsible for the entire template because no
one plugin knows about the other plugins being used. For instance, if an RSpec
plugin was added to support and document specifications in class templates,
this information would need to be transparently added to the template to work
in conjunction with any other plugin that performed similar template modifications.
The design goals can be summarized as follows:

  1. Output should be able to be generated for any arbitrary format with little
     modification to YARD's source code. The addition of extra templates should
     be sufficient.
  2. The output generated for an object should independently generated data
     from arbitrary sources. These independent components are called "sections".
  3. Sections should be able to be inserted into any object without affecting
     any existing sections in the document. This allows for easy modification
     of templates by plugins.
     
Generators
----------

Generator classes are the objects used to orchestrate the design goals listed 
above. Specifically, they organize the sections and render the template contents
depending on the format. The main method used to initiate output is the 
{YARD::Generators::Base#generate #generate} method which takes a list of
objects to generate output for. A good example of this is the FullDocGenerator,
which generates conventional HTML documentation:

    # all_objects is an array of module and class objects
    Generators::FullDocGenerator.new(options).generate(all_objects)

Generator Options
-----------------

A generator keeps state when it is generating output. This state is kept in
an options hash which is initially passed to it during instantiation. Some
default options set the template style (`:template`), the output format (`:format`),
and the serializer to use (`:serializer`). For example, initializing the 
{YARD::Generators::QuickDocGenerator} to output as text instead of HTML can be
done as follows:

    YARD::Generators::QuickDocGenerator.new(:format => :text).generate(objects)
    
Serializer
----------

This class abstracts the logic involved in deciding how to serialize data to
the expected endpoint. For instance, there is both a {YARD::Serializers::StdoutSerializer StdoutSerializer}
and {YARD::Serializers::FileSystemSerializer FileSystemSerializer} class for
outputting to console or to a file respectively. When endpoints with locations
are used (like files or URLs), the serializer implements the {YARD::Serializers::Base#serialized_path #serialized_path}
method. This allows the translation from a code object to its path at the endpoint,
which enables inter-document linking.

Generated objects are automatically serialized using the object if present, 
otherwise the generated object is returned as a string to its parent. Nested
generator objects automatically set the serializer to nil so that they return
as a String to their parent.

Templates
---------

Templates for a generator are by default found inside the one of the template 
root paths (there can be multiple template paths). A standard template 
directory looks like the following tree:

    (Assuming templates/ is a template root path)
    templates/
    |-- default
    |   |-- attributes
    |   |   |-- html
    |   |   |   `-- header.erb
    |   |   `-- text
    |   |       `-- header.erb
    |   |-- class
    |   |   `-- html
    |   |       `-- header.erb
    |   |-- constants
    |   |   `-- html
    |   |       |-- constants.erb
    |   |       |-- header.erb
    |   |       |-- included.erb
    |   |       `-- inherited.erb
    ...

The path `default` refers to the template style and the directories at the next
level (such as `attributes`) refer to templates for a generator. The next directory
refers to the output format being used defined by the `:format` generator option. 
As we saw in the above example, the format option can be set to `:text`, which
would use the `text/` directory instead of `html/`. Finally, the individual .erb 
files are the sections that make up the generator. 

Sections
--------

As mentioned above, sections are smaller components that correlate to template
fragments. Practically speaking, a section can either be a template fragment 
(a conventional .erb file or other supported templating language), a method 
(which returns a String) or another Generator object (which in turn has its own 
list of sections).

Creating a Generator
--------------------

To create a generator, subclass {YARD::Generators::Base} and implement the
`#sections_for(object)` method. This method should return a list of sections where
a Symbol refers to a method or template name and a class refers to a generator.

    def sections_for(object)
      case object
      when MethodObject
        [:main, [G(AnotherGenerator)], :footer]
      else
        []
      end
    end
    
A few points about the above example:

  * The method can return different lists depending on the object.
  * The list of objects is not flat, we will see how nested lists can be used
    in a future example.
  * The convenience method `G()` instantiates a generator out of the class using
    the existing options.

If a section is a Symbol, the generator first checks if a method is defined
with that name, otherwise it checks in the template directories. If a method
by the symbol name is defined, you need to manually call {YARD::Generators::Base#render #render}
to return the contents of the template.

Nested Sections
---------------

Sections often require the ability to encapsulate a set of sub-sections in markup
(HTML, for instance). Rather than use heavier Generator subclass objects, a more
lightweight solution is to nest a set of sub-sections as a list that follows
a section, for example:

    def sections_for(object) 
      [:header, [:section_a, :section_b]]
    end
    
The above example nests `section_a` and `section_b` within the `header` section.
Practically speaking, these sections can be placed in the result by `yield`ing
to them. A sample header.erb template might contain:

    &lt;h2&gt;Header&lt;/h2&gt;
    &lt;div id=&quot;contents&quot;&gt;
      &lt;%= yield %&gt;
    &lt;/div&gt;
    
This template code would place the output of `section_a` and `section_b` within
the above div element. Using yield, we can also change the object that is being
generated. For example, we may want to yield the first method of the class.
We can do this like so:

    &lt;h2&gt;First method&lt;/h2&gt;
    &lt;%= yield(current_object.meths.first) %&gt;

This would run the nested sections for the method object instead of the class.

Before Filters
--------------

Generators can run before filters using the {YARD::Generators::Base.before_section before_section} method
for all or a specific section to test if the section should be generated or 
skipped. For instance, we can do the following to generate the section :foo only 
for MethodObjects:

    class MyGenerator < YARD::Generators::Base
      before_section :foo, :is_method?
      
      def sections_for(object)
        [:foo, :bar, :baz]
      end
      
      private
      
      def is_method?(object)
        object.is_a?(MethodObject)
      end
    end

Without the argument `:foo`, the before filter would be applied to all sections.
Note that we must return `false` to skip a section. A return type of nil is not
enough to skip the section.

There is also a {YARD::Generators::Base.before_list before_list} method to run
a filter before the entire generator is run. This is useful for doing necessary
filesystem setup or for generating assets (stylesheets) before generating output 
for the objects. Note that in this case you will need to serialize your data directly
using the serializer object (described above).
