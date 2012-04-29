# @title Tags Overview

# Tags Overview

Tags represent the metadata that can be added to documentation through the `@tag`
style syntax:

    # @tagname some data
    class Foo
    end

The above example adds metadata under the name `tagname` to the Foo class object.

Tags are the best way to add arbitrary metadata when documenting an object in a
way to access it later without having to parse the entire comment string. The
rest of the document will describe the tag syntax, how to access the tag
metadata and how to extend YARD to support custom tags or override existing tags.

## Tag Syntax

Tags begin with "@tagname" at the start of a comment line. Tags can span multiple
lines if the subsequent lines are indented by more than one space. The following
syntax is valid:

    # @tagname This is
    #   tag data
    # but this is not

In the above example, "@tagname" will have the text *"This is tag data"*.

If a tag's data begins with `(see NAME)` it is considered a "reference tag".
The syntax and semantics of a reference tag are discussed in the section below
titled "[Reference Tags](#reftags)"

Although custom tags can be parsed in any way, the built-in tags follow a few
common syntax structures by convention in order to simplify the syntax. The
following syntaxes are available:

### Freeform Data

This syntax has no special syntax, it is simply a tagname followed by any
data.

    !!!plain
    @tagname data here

### Freeform Data With Title

Occasionally a freeform tag may reserve the first line for a title (or some
other associative identifier) and treat only the subsequent indented lines as
the tag data. Two examples are the `@example` and `@overload` tags. In the case
of `@example` the first line is a title, and in the case of `@overload` the
first line is the method signature for the overload. Here is an example of both:

    @example Reverse a string
      "hello world".reverse

    @overload request(method = :get, url = 'http://example.com')
      Performs a request on +url+
      @param [Symbol] method the request method
      @param [String] url the URL to perform the request on
      @return [String] the result body (no headers)

### Data With Optional Type Information

This syntax optionally contains type information to be associated with the
tag. Type information is specified as a freeform list of Ruby types, duck
types or literal values. The following is a valid tag with type information:

    !!!plain
    @return [String, #read] a string or object that responds to #read

### Data With Name and Optional Type Information

A special case of the above data with optional type information is the case
of tags like `@param`, where the data is further associated with a key. In
the case of `@param` the key is an argument name in the method. The following
shows how this can be used:

    !!!plain
    @param [String] url the URL to perform the request on

Note that "url" in the above example is the key name. The syntax is of the form:

    !!!plain
    @tagname [types] <name> <description>

As mentioned, types are optional, so the following is also valid:

    !!!plain
    @param url the URL to perform the request on

<a name="reftags"></a>

## Reference Tags

Although attempt is made in YARD to leave as many of the syntax details as
possible to the factory provider, there is a special tag syntax for referencing
tags created in other objects so that they can be reused again. This is common
when an object describes a return type or parameters that are passed through to
other methods. In such a case, it is more manageable to use the reference tag
syntax. Consider the following example:

    class User
      # @param [String] username the name of the user to add
      # @param [Numeric] uid the user ID
      # @param [Numeric] gid the group ID
      def initialize(username, uid, gid)
      end
    end

    module UserHelper
      # @param (see User#initialize)
      def add_user(username, uid, gid)
        User.new(username, uid, gid)
      end

      # @param username (see User#initialize)
      def add_root_user(username)
        User.new(username, 0, 0)
      end
    end

Because the UserHelper module methods delegate directly to `User.new`, copying
the documentation details would be unmaintainable. In this case, the (see METHODNAME)
syntax is used to reference the tags from the User constructor to the helper methods.
For the first method, all `@param` tags are referenced in one shot, but the second
method only references one of the tags by adding `username` before the reference.

Reference tags are represented by the {YARD::Tags::RefTag} class and are created
directly during parsing by {YARD::Docstring}.

<a name="taglist"></a>

{yard:include_tags}

