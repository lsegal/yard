# frozen_string_literal: true

begin
  require 'prism'
rescue LoadError
  nil
end

module YARD
  module Handlers
    # A processor that walks the Prism AST directly and creates CodeObjects
    # without building an intermediate AstNode tree. This is significantly
    # faster than the Processor + Handler pipeline because it eliminates
    # thousands of intermediate object allocations.
    class PrismProcessor
      include CodeObjects
      include Handlers::Ruby::StructHandlerMethods

      attr_accessor :file, :namespace, :visibility, :scope, :owner
      attr_accessor :globals, :extra_state

      # @param source_parser [YARD::Parser::SourceParser]
      def initialize(source_parser)
        @file = source_parser.file || "(stdin)"
        @source = source_parser.contents
        @namespace = Registry.root
        @visibility = :public
        @scope = :instance
        @owner = @namespace
        @globals = source_parser.globals || OpenStruct.new
        @extra_state = OpenStruct.new
        @source_parser = source_parser
        @comments = {}
        @comments_range = {}
        @comments_flags = {}
        @comments_start = {}
      end

      def parser_type; :ruby end

      # Walk only documentation-relevant nodes. Unlike Prism::Compiler
      # (which dispatches to every node in the tree), this only recurses
      # into nodes that can contain class/module/method/constant
      # definitions or visibility changes.
      def visit(node)
        case node.type
        when :program_node
          node.statements&.body&.each { |child| visit(child) }
        when :statements_node
          node.body.each { |child| visit(child) }
        when :class_node then visit_class(node)
        when :singleton_class_node then visit_singleton_class(node)
        when :module_node then visit_module(node)
        when :def_node then visit_def(node)
        when :call_node then visit_call(node)
        when :alias_method_node then visit_alias_method(node)
        when :constant_write_node then visit_constant_write(node)
        when :constant_path_write_node then visit_constant_path_write(node)
        when :class_variable_write_node then visit_class_variable_write(node)
        when :yield_node then visit_yield(node)
        when :if_node then visit_if(node)
        when :unless_node then visit_unless(node)
        when :else_node
          visit(node.statements) if node.statements
        # begin/rescue/ensure blocks are not traversed for documentation
        # (matching Ripper, which has no handler for :begin nodes).
        when :case_node, :case_match_node
          node.conditions.each { |c| visit(c) }
          visit(node.else_clause) if node.else_clause
        when :when_node, :in_node, :while_node, :until_node, :for_node
          visit(node.statements) if node.statements
        when :lambda_node
          visit(node.body) if node.body
        when :parentheses_node
          visit(node.body) if node.body
        # shareable_constant_value pragma wraps constants in this node
        when :shareable_constant_node
          visit(node.write)
        # ||= / &&= / += on constants may have Struct.new/class on RHS
        when :constant_or_write_node, :constant_and_write_node,
             :constant_operator_write_node,
             :constant_path_or_write_node, :constant_path_and_write_node,
             :constant_path_operator_write_node
          visit(node.value)
        # Variable writes may contain class/struct definitions on the RHS
        when :local_variable_write_node, :instance_variable_write_node,
             :global_variable_write_node
          visit(node.value)
        end
        # All other node types are silently skipped — they cannot
        # contain documentation-relevant definitions.
      end

      # Visit a namespace body, processing standalone directive comments
      # (matching Ripper's CommentHandler) between code nodes.
      # A comment is "standalone" if it is more than 2 lines away from
      # the nearest code node, meaning consume_comment would never
      # pick it up.
      def visit_ns_body(body_node, end_line = nil)
        stmts = if body_node.nil?
          []
        elsif body_node.is_a?(Prism::StatementsNode)
          body_node.body
        else
          [body_node]
        end
        sorted_comment_lines = @comments.keys.sort
        comment_idx = 0
        ns_end = end_line || body_node.location.end_line
        stmts.each do |child|
          child_start = child.location.start_line
          comment_idx = process_directives(sorted_comment_lines, comment_idx, child_start - 2)
          next if child.is_a?(Prism::BeginNode)
          visit(child)
        end
        process_directives(sorted_comment_lines, comment_idx, ns_end)
      end

      def process_directives(sorted_lines, idx, up_to_line)
        while idx < sorted_lines.size
          line = sorted_lines[idx]
          break if line > up_to_line
          idx += 1
          comment = @comments[line]
          next unless comment && !comment.empty?
          next unless comment =~ /^\s*@/
          comment = @comments.delete(line)
          hash_flag = @comments_flags.delete(line)
          @comments_range.delete(line)
          start = @comments_start.delete(line) || line
          line_range = start..line
          @current_statement = StatementProxy.new("", line, comment, hash_flag, line_range)
          register_docstring(nil, comment, nil, hash_flag, line_range)
          @current_statement = nil
        end
        idx
      end

      def visit_class(node)
        class_name = resolve_path(node.constant_path)
        superclass_name = node.superclass ? resolve_path(node.superclass) : nil

        # Handle Struct.new / Data.define superclass
        if node.superclass.is_a?(Prism::CallNode)
          struct_info = detect_struct_or_data(node.superclass)
          if struct_info
            klass = create_struct_class(class_name, struct_info, node)
            attach_comment(klass, node)
            push_state(namespace: klass) do
              visit_ns_body(node.body, node.end_keyword_loc&.start_line)
            end
            return
          end
        end

        @current_line = node.location.start_line
        klass = register ClassObject.new(namespace, class_name) { |o|
          if superclass_name
            o.superclass = superclass_name
            o.superclass.type = :class if o.superclass.is_a?(Proxy)
          end
        }
        attach_comment(klass, node)
        push_state(namespace: klass) do
          visit_ns_body(node.body, node.end_keyword_loc&.start_line)
        end
      end

      def visit_singleton_class(node)
        expr = node.expression
        if expr.is_a?(Prism::SelfNode)
          push_state(namespace: namespace, scope: :class) do
            visit_ns_body(node.body, node.end_keyword_loc&.start_line)
          end
        elsif constant_node?(expr)
          name = resolve_path(expr)
          obj = Proxy.new(namespace, name)
          obj = register ClassObject.new(namespace, name) if obj.is_a?(Proxy)
          push_state(namespace: obj, scope: :class) do
            visit_ns_body(node.body, node.end_keyword_loc&.start_line)
          end
        end
      end

      def visit_module(node)
        mod_name = resolve_path(node.constant_path)
        @current_line = node.location.start_line
        mod = register ModuleObject.new(namespace, mod_name)
        attach_comment(mod, node)
        push_state(namespace: mod) do
          visit_ns_body(node.body, node.end_keyword_loc&.start_line)
        end
      end

      def visit_def(node)
        meth = node.name_loc.slice
        nobj = namespace
        mscope = scope

        if node.receiver
          if constant_node?(node.receiver)
            nobj = P(namespace, resolve_path(node.receiver))
          elsif !node.receiver.is_a?(Prism::SelfNode)
            return # method defined on object instance - skip
          end
          mscope = :class
        end

        nobj = P(namespace, nobj.value) while nobj.is_a?(CodeObjects::ConstantObject)

        args = format_args(node.parameters)
        @current_line = node.location.start_line
        obj = register MethodObject.new(nobj, meth, mscope) { |o|
          o.explicit = true
          o.parameters = args
        }
        attach_comment(obj, node)
        register_source_from_node(obj, node)
        register_group(obj)

        # When scope is :module, register_module_function already created
        # a private instance copy before attach_comment ran. Re-sync the
        # docstring from the now-populated class method to the instance copy.
        if obj.module_function?
          inst = nobj.child(name: meth.to_sym, scope: :instance)
          if inst
            saved_vis = inst.visibility
            obj.copy_to(inst)
            inst.visibility = saved_vis
          end
        end

        # Delete old aliases referencing this method
        if nobj.is_a?(NamespaceObject)
          nobj.aliases.each do |aobj, name|
            nobj.aliases.delete(aobj) if name == obj.name
          end
        end

        # Constructor auto-tags
        if obj.constructor?
          unless obj.has_tag?(:return)
            obj.add_tag(Tags::Tag.new(:return, "a new instance of #{namespace.name}", namespace.name.to_s))
          end
        elsif mscope == :class && obj.docstring.blank? &&
              %w[inherited included extended method_added method_removed method_undefined].include?(meth)
          obj.add_tag(Tags::Tag.new(:private, nil))
        elsif meth =~ /\?$/
          add_predicate_return_tag(obj)
        end

        # Option tags
        if obj.has_tag?(:option)
          obj.tags(:option).each do |option|
            unless obj.tags(:param).find { |x| x.name == option.name }
              obj.add_tag(Tags::Tag.new(:param, "a customizable set of options", "Hash", option.name))
            end
          end
        end

        # Attr info linking
        if (info = obj.attr_info)
          if meth =~ /=$/
            info[:write] = obj if info[:read]
          elsif info[:write]
            info[:read] = obj
          end
        end

        # Parse body for yield/raise
        push_state(owner: obj) do
          visit(node.body) if node.body
        end
      end

      def visit_call(node)
        # Only handle bare calls and commands (no receiver, or receiver is self/const)
        if node.receiver.nil?
          handle_bare_call(node)
        elsif node.receiver.is_a?(Prism::SelfNode) && node.call_operator_loc
          # self.method_name - could be a class method call like self.include
          handle_bare_call(node)
        else
          # Regular method calls - only recurse into block (if any),
          # which may contain class/method definitions.
          visit(node.block) if node.block
        end
      end

      def visit_alias_method(node)
        register_alias(
          symbol_or_ident_name(node.new_name),
          symbol_or_ident_name(node.old_name),
          node
        )
      end

      def visit_constant_write(node)
        visit_constant_assign(node.name.to_s, node)
      end

      def visit_constant_path_write(node)
        target_path = resolve_path(node.target)
        visit_constant_assign(target_path, node) if target_path
      end

      def visit_constant_assign(name, node)
        if node.value.is_a?(Prism::CallNode)
          struct_info = detect_struct_or_data(node.value)
          if struct_info
            klass = create_struct_class(name, struct_info, node)
            attach_comment(klass, node)
            if node.value.block
              push_state(namespace: klass) do
                visit(node.value.block.body) if node.value.block.body
              end
            end
            return
          end
        end

        return unless owner.is_a?(NamespaceObject)

        @current_line = node.location.start_line
        obj = register ConstantObject.new(namespace, name) { |o|
          o.source = node.slice
          o.value = node.value.slice
        }
        attach_comment(obj, node)
      end

      def visit_class_variable_write(node)
        return unless owner.is_a?(NamespaceObject)
        @current_line = node.location.start_line
        name = node.name.to_s
        obj = register ClassVariableObject.new(namespace, name) { |o|
          o.source = node.slice
          o.value = node.value.slice
        }
        attach_comment(obj, node)
      end

      def visit_yield(node)
        return unless owner.is_a?(MethodObject)
        return if owner.has_tag?(:yield) || owner.has_tag?(:yieldparam)

        if node.arguments
          names = node.arguments.arguments.map { |p| p.slice }
          owner.add_tag(Tags::Tag.new(:yield, "", names))
          names.each do |n|
            owner.add_tag(Tags::Tag.new(:yieldparam, "", n, "_#{n}"))
          end
        end
      end

      def visit_if(node)
        # Modifier if: just visit the body
        if node.end_keyword_loc.nil? && node.if_keyword_loc
          visit(node.statements) if node.statements
          return
        end

        # Regular if/elsif
        if node.if_keyword_loc && node.if_keyword_loc.slice == "elsif"
          visit(node.statements) if node.statements
          visit(node.subsequent) if node.subsequent
          return
        end

        # Try to evaluate condition
        result = evaluate_condition(node.predicate)
        if result == true
          visit(node.statements) if node.statements
        elsif result == false
          visit(node.subsequent) if node.subsequent
        else
          # Unknown condition - visit both branches
          saved_vis = visibility
          visit(node.statements) if node.statements
          self.visibility = saved_vis
          visit(node.subsequent) if node.subsequent
          self.visibility = saved_vis
        end
      end

      def visit_unless(node)
        if node.end_keyword_loc.nil? && node.keyword_loc
          visit(node.statements) if node.statements
          return
        end

        result = evaluate_condition(node.predicate)
        if result.nil?
          saved_vis = visibility
          visit(node.statements) if node.statements
          self.visibility = saved_vis
          visit(node.else_clause) if node.else_clause
          self.visibility = saved_vis
        elsif result == false
          visit(node.statements) if node.statements
        else
          visit(node.else_clause) if node.else_clause
        end
      end

      # ---- Call handling ----

      def handle_bare_call(node)
        case node.name
        when :attr, :attr_reader, :attr_writer, :attr_accessor
          handle_attribute(node)
        when :public, :private, :protected
          handle_visibility(node)
        when :include, :prepend
          handle_mixin(node, node.name)
        when :extend then handle_extend(node)
        when :module_function then handle_module_function(node)
        when :alias_method then handle_alias_method(node)
        when :private_constant then handle_private_constant(node)
        when :private_class_method then handle_class_method_visibility(node, :private)
        when :public_class_method then handle_class_method_visibility(node, :public)
        when :raise then handle_raise(node)
        else
          handle_dsl(node, node.name.to_s)
        end
      end

      def handle_attribute(node)
        return unless owner.is_a?(NamespaceObject)
        name = node.name.to_s.to_sym

        read = true
        write = false
        case name
        when :attr_accessor then write = true
        when :attr_writer then read = false; write = true
        when :attr
          # Second arg being true means writable
          if node.arguments && node.arguments.arguments.size == 2
            second = node.arguments.arguments[1]
            if second.is_a?(Prism::TrueNode)
              write = true
            end
          end
        end

        # Consume comment once, reuse for all generated methods
        @current_line = node.location.start_line
        cd = consume_comment(node)

        extract_symbols(node).each do |attr_name|
          namespace.attributes[scope][attr_name] ||= SymbolHash[read: nil, write: nil]

          { read: attr_name, write: "#{attr_name}=" }.each do |type, meth|
            next unless type == :read ? read : write
            o = register MethodObject.new(namespace, meth, scope)
            if cd
              register_docstring(o, cd.text, node, cd.hash_flag, cd.line_range)
            end
            if type == :write
              o.parameters = [['value', nil]]
              o.source ||= "def #{meth}(value)\n  @#{attr_name} = value\nend"
              o.signature ||= "def #{meth}(value)"
              o.docstring = "Sets the attribute #{attr_name}\n@param value the value to set the attribute #{attr_name} to." if o.docstring.blank?(false)
            else
              o.source ||= "def #{meth}\n  @#{attr_name}\nend"
              o.signature ||= "def #{meth}"
              o.docstring = "Returns the value of attribute #{attr_name}." if o.docstring.blank?(false)
            end
            namespace.attributes[scope][attr_name][type] = o
          end
        end
      end

      def handle_visibility(node)
        vis = node.name

        unless node.arguments
          # Bare call: private/public/protected
          self.visibility = vis
          globals.visibility_origin = :keyword
          return
        end

        # With arguments: set visibility on named methods
        extract_symbols(node).each do |meth_name|
          obj = namespace.child(name: meth_name.to_sym, scope: scope)
          obj.visibility = vis if obj
        end
      end

      def handle_mixin(node, method_name)
        return unless owner.is_a?(NamespaceObject)
        return unless node.arguments

        shift = method_name == :include ? :unshift : :push
        node.arguments.arguments.reverse_each do |arg|
          next unless constant_node?(arg)
          mixin_path = resolve_path(arg)
          obj = Proxy.new(namespace, mixin_path, :module)

          begin
            ensure_loaded!(namespace)
          rescue NamespaceMissingError
            next
          end
          next if namespace.mixins(scope).include?(obj)
          namespace.mixins(scope).send(shift, obj)
        end
      end

      def handle_extend(node)
        return unless owner.is_a?(NamespaceObject)
        return unless node.arguments

        node.arguments.arguments.each do |arg|
          if arg.is_a?(Prism::SelfNode)
            namespace.mixins(:class) << namespace unless namespace.is_a?(ClassObject)
          elsif constant_node?(arg)
            mixin_path = resolve_path(arg)
            obj = Proxy.new(namespace, mixin_path, :module)
            begin
              ensure_loaded!(namespace)
            rescue NamespaceMissingError
              next
            end
            namespace.mixins(:class).unshift(obj) unless namespace.mixins(:class).include?(obj)
          end
        end
      end

      def handle_module_function(node)
        unless node.arguments
          self.scope = :module
          return
        end

        extract_symbols(node).each do |meth_name|
          inst_method = namespace.child(name: meth_name.to_sym, scope: :instance)
          if inst_method
            cls_method = MethodObject.new(namespace, meth_name, :module)
            inst_method.copy_to(cls_method)
            cls_method.visibility = :public
            register cls_method
          end
        end
      end

      def handle_alias_method(node)
        return unless node.arguments
        args = node.arguments.arguments
        return unless args.size >= 2
        register_alias(symbol_name(args[0]), symbol_name(args[1]), node)
      end

      def handle_private_constant(node)
        extract_symbols(node).each do |const_name|
          obj = namespace.child(name: const_name.to_sym)
          obj.visibility = :private if obj
        end
      end

      def handle_class_method_visibility(node, vis)
        extract_symbols(node).each do |meth_name|
          obj = namespace.child(name: meth_name.to_sym, scope: :class)
          obj.visibility = vis if obj
        end
      end

      def handle_raise(node)
        return unless owner.is_a?(MethodObject)
        return if owner.has_tag?(:raise)
        return unless node.arguments

        args = node.arguments.arguments
        return if args.empty?

        first = args[0]
        klass = if constant_node?(first)
          resolve_path(first)
        elsif first.is_a?(Prism::CallNode) && first.name == :new &&
              constant_node?(first.receiver)
          resolve_path(first.receiver)
        end
        owner.add_tag(Tags::Tag.new(:raise, "", klass)) if klass
      end

      def handle_dsl(node, name)
        return unless owner.is_a?(NamespaceObject)
        return if Handlers::Ruby::DSLHandlerMethods::IGNORE_METHODS[name]

        cd = consume_comment(node)
        comment = cd ? cd.text : ""
        comment_hash_flag = cd&.hash_flag
        line_range = cd&.line_range

        @current_statement = StatementProxy.new(
          node.slice, node.location.start_line, comment,
          comment_hash_flag, line_range
        )
        @current_caller_method = name
        @current_call_params = call_params_from(node)

        attaching = false
        if comment =~ /^@!?macro\s+\[[^\]]*attach/
          register_docstring(nil, comment, node)
          comment = ""
          attaching = true
        end

        # Look for an attached macro from the method definition
        macro = find_attached_macro(name)
        if macro
          txt = macro.expand([name, *@current_call_params], node.slice)
          comment = comment.empty? ? txt : comment + "\n" + txt

          # Macro may have a directive — register docstring only
          if !attaching && txt.match(/^\s*@!/)
            register_docstring(nil, comment, node)
            return
          end
        elsif !comment_hash_flag && !implicit_docstring?(comment)
          register_docstring(nil, comment, node) unless comment.empty?
          return
        end

        # If @!method or @!attribute directive is used, register docstring only
        if comment =~ /^@!?(method|attribute)\b/
          register_docstring(nil, comment, node)
          return
        end

        # Create method object from DSL call
        meth_name = dsl_method_name
        return unless meth_name

        obj = register MethodObject.new(namespace, meth_name, scope) { |o|
          o.signature = "def #{meth_name}"
        }
        register_docstring(obj, comment, node)
      ensure
        @current_statement = nil
        @current_caller_method = nil
        @current_call_params = nil
      end

      # ---- State management ----

      def push_state(opts = {})
        saved_ns, saved_sc, saved_ow, saved_vis = @namespace, @scope, @owner, @visibility
        @namespace = opts[:namespace] if opts[:namespace]
        @scope = opts[:scope] || :instance
        @owner = opts[:owner] || @namespace
        @visibility = opts[:visibility] || :public if opts.key?(:namespace)
        yield
      ensure
        @namespace, @scope, @owner, @visibility = saved_ns, saved_sc, saved_ow, saved_vis
      end

      def ensure_loaded!(object, max_retries = 1)
        return if object.root?
        return object unless object.is_a?(Proxy)
        retries = 0
        while object.is_a?(Proxy)
          raise NamespaceMissingError, object if retries > max_retries
          log.debug "Missing object #{object} in file `#{@file}', moving it to the back of the line."
          parse_remaining_files
          retries += 1
        end
        object
      end

      def parse_remaining_files
        if globals.ordered_parser
          globals.ordered_parser.parse
          log.debug("Re-processing #{@file}...")
        end
      end

      # ---- Register pipeline ----

      def register(*objects)
        objects.flatten.each do |object|
          next unless object.is_a?(CodeObjects::Base)
          register_ensure_loaded(object)
          yield(object) if block_given?
          register_file_info(object)
          register_visibility(object)
          register_group(object)
          register_dynamic(object)
          register_module_function(object)
        end
        objects.size == 1 ? objects.first : objects
      end

      def register_ensure_loaded(object)
        ensure_loaded!(object.namespace)
        object.namespace.children << object
      rescue NamespaceMissingError
        nil
      end

      def register_file_info(object, line = @current_line, comments = nil)
        object.add_file(@file, line, comments)
      end

      def register_visibility(object, vis = self.visibility)
        return unless object.respond_to?(:visibility=)
        return if object.is_a?(NamespaceObject)
        if object.is_a?(MethodObject)
          origin = globals.visibility_origin
          if origin == :keyword
            object.visibility = vis if object.scope == scope
          else
            object.visibility = vis
          end
        else
          object.visibility = vis
        end
      end

      def register_group(object, group = extra_state.group)
        if group
          unless object.namespace.is_a?(Proxy)
            object.namespace.groups |= [group]
          end
          object.group = group
        end
      end

      def register_dynamic(object)
        object.dynamic = true if owner != namespace
      end

      def register_module_function(object)
        return unless object.is_a?(MethodObject) && object.module_function?
        modobj = MethodObject.new(object.namespace, object.name)
        object.copy_to(modobj)
        modobj.visibility = :private
      end

      def register_transitive_tags(object)
        return unless object && !object.namespace.is_a?(Proxy)
        Tags::Library.transitive_tags.each do |tag|
          next unless object.namespace.has_tag?(tag)
          next if object.has_tag?(tag)
          object.add_tag(*object.namespace.tags(tag))
        end
      end

      def register_source(object, _source = nil)
        return unless object.is_a?(MethodObject)
        object.source_type = :ruby
      end

      # Directive compatibility - directives expect `handler.parser` to be
      # a Processor-like object with `file` and `process`. We return self.
      def parser; self end

      # @parse directive compatibility - process an enumerator of AstNodes
      # by falling back to the traditional Processor pipeline.
      def process(enumerator_or_result)
        if enumerator_or_result.is_a?(Prism::ParseResult)
          index_prism_comments(enumerator_or_result.comments)
          visit(enumerator_or_result.value)
          # Process any remaining directive comments not consumed by visit
          process_remaining_comments
        elsif enumerator_or_result && enumerator_or_result != false
          # Fallback: old-style AstNode enumerator from @parse directive
          post = Processor.new(@source_parser)
          post.process(enumerator_or_result)
        end
      end
      def statement; @current_statement || NullStatement end
      def call_params; @current_call_params || [] end
      def caller_method; @current_caller_method end

      # Minimal statement-like object for directive compatibility
      StatementProxy = Struct.new(:source, :line, :comments, :comments_hash_flag, :comments_range)
      NullStatement = StatementProxy.new("", 0, nil, nil, nil).freeze

      # Consumed comment data returned by consume_comment_at
      CommentData = Struct.new(:text, :hash_flag, :range, :line_range)

      # ---- Comment handling ----

      def index_prism_comments(prism_comments)
        last_line = nil
        last_column = nil

        prism_comments.each do |comment|
          loc = comment.location
          line = loc.start_line
          col = loc.start_column
          source_start = loc.start_character_offset
          source_end = loc.end_character_offset - 1

          case comment
          when Prism::EmbDocComment
            text = loc.slice
            lines = text.split("\n")
            lines.shift # =begin
            lines.pop if lines.last&.start_with?("=end")
            content = lines.join("\n") + "\n"
            end_line = loc.end_line
            @comments[end_line] = content
            @comments_range[end_line] = source_start...source_end
            @comments_start[end_line] = loc.start_line
            last_line = nil
            last_column = nil
          when Prism::InlineComment
            text = loc.slice
            if SPECIAL_COMMENT_RE.match?(text)
              last_line = nil
              last_column = nil
              next
            end

            content = text.sub(/\A(\#+)\s{0,1}/, '').chomp
            hash_flag = $1 == '##' ? true : false
            source_range = source_start..source_end

            if last_line == line - 1 && last_column == col && !comment.trailing?
              prev_content = @comments.delete(last_line)
              prev_range = @comments_range.delete(last_line)
              prev_flag = @comments_flags.delete(last_line)
              prev_start = @comments_start.delete(last_line)
              source_range = prev_range.begin..source_range.end
              content = prev_content + "\n" + content
              @comments_flags[line] = prev_flag
              @comments_start[line] = prev_start
            else
              @comments_flags[line] = hash_flag
              @comments_start[line] = line
            end

            @comments[line] = content
            @comments_range[line] = source_range
            last_line = line
            last_column = col
          end
        end
      end

      def process_remaining_comments
        @comments.keys.sort.each do |line|
          comment = @comments[line]
          next unless comment && !comment.empty?
          next unless comment =~ /^\s*@/
          comment = @comments.delete(line)
          hash_flag = @comments_flags.delete(line)
          @comments_range.delete(line)
          start = @comments_start.delete(line) || line
          line_range = start..line
          @current_statement = StatementProxy.new("", line, comment, hash_flag, line_range)
          register_docstring(nil, comment, nil, hash_flag, line_range)
          @current_statement = nil
        end
      end

      SPECIAL_COMMENT_RE = Regexp.union(
        Parser::SourceParser::SHEBANG_LINE,
        Parser::SourceParser::ENCODING_LINE,
        Parser::SourceParser::FROZEN_STRING_LINE
      ).freeze


      def find_comment(node)
        line = node.location.start_line
        comment_at(line - 1) || comment_at(line - 2) || comment_at(line)
      end

      def consume_comment(node)
        line = node.location.start_line
        consume_comment_at(line - 1) || consume_comment_at(line - 2) || consume_comment_at(line)
      end

      def comment_at(line)
        c = @comments[line]
        c && !c.empty? ? c : nil
      end

      def consume_comment_at(line)
        c = @comments[line]
        return nil unless c && !c.empty?
        start = @comments_start.delete(line) || line
        CommentData.new(
          @comments.delete(line),
          @comments_flags.delete(line),
          @comments_range.delete(line),
          start..line
        )
      end

      def attach_comment(object, node)
        @current_line = node.location.start_line
        cd = consume_comment(node)
        return unless cd
        @current_statement = StatementProxy.new(
          node.slice, @current_line, cd.text, cd.hash_flag, cd.line_range
        )
        register_docstring(object, cd.text, node, cd.hash_flag, cd.line_range)
        @current_statement = nil
      end

      def register_docstring(object, docstring = nil, _node = nil, hash_flag = nil, range = nil)
        docstring = docstring.join("\n") if Array === docstring
        parser = Docstring.parser
        parser.parse(docstring || "", object, self)

        if object && docstring
          object.docstring = parser.to_docstring
          object.docstring.hash_flag = hash_flag unless hash_flag.nil?
          object.docstring.line_range = range if range
        end

        if docstring.is_a?(String)
          if (m = docstring.match(VISIBILITY_DIRECTIVE_RE))
            vis_sym = m[1].to_sym
            if object.nil?
              globals.visibility_origin = :directive
            elsif object.is_a?(MethodObject)
              object.visibility = vis_sym
            end
          end
        end

        register_transitive_tags(object)
      end

      # ---- Utility ----

      def constant_node?(node)
        node.is_a?(Prism::ConstantReadNode) || node.is_a?(Prism::ConstantPathNode)
      end

      def resolve_path(node)
        case node.type
        when :constant_read_node
          node.name.to_s
        when :constant_path_node
          node.full_name
        when :call_node
          resolve_path(node.receiver) if node.receiver
        when :self_node
          "self"
        else
          node.slice
        end
      end


      def register_source_from_node(object, node)
        return unless object.is_a?(MethodObject)
        object.source ||= node.slice
        object.signature ||= build_signature(node)
        object.source_type = :ruby
      end

      def build_signature(node)
        sig = node.receiver ? "def #{node.receiver.slice}.#{node.name}" : "def #{node.name}"
        if node.parameters
          params_src = node.parameters.slice.gsub(/\s+(\s|\))/m, '\1')
          sig += node.lparen_loc ? "(#{params_src})" : " #{params_src}"
        end
        sig
      end

      def register_alias(new_name, old_name, node)
        return unless new_name && old_name
        new_obj = register MethodObject.new(namespace, new_name, scope)
        old_obj = namespace.child(name: old_name.to_sym, scope: scope) if namespace.is_a?(NamespaceObject)
        if old_obj
          new_obj.signature = old_obj.signature
          new_obj.source = old_obj.source
          alias_comment = find_comment(node) || ""
          comments = [old_obj.docstring.to_raw, alias_comment].join("\n")
          doc = Docstring.parser.parse(comments, new_obj, self)
          new_obj.docstring = doc.to_docstring
          new_obj.docstring.object = new_obj
        else
          attach_comment(new_obj, node)
          new_obj.signature = "def #{new_name}"
        end
        namespace.aliases[new_obj] = old_name.to_sym if namespace.is_a?(NamespaceObject)
      end

      def symbol_or_ident_name(node)
        case node.type
        when :symbol_node then node.value.to_s
        when :call_node then node.name.to_s
        when :interpolated_symbol_node then node.slice.delete_prefix(":").delete_prefix('"').delete_suffix('"')
        else node.slice
        end
      end

      def symbol_name(node)
        case node.type
        when :symbol_node then node.value.to_s
        when :string_node then node.content
        end
      end

      def extract_symbols(node)
        return [] unless node.arguments
        node.arguments.arguments.filter_map { |arg| symbol_name(arg) }
      end

      def format_args(params_node)
        return [] unless params_node

        params = []

        params_node.requireds.each do |p|
          params << [p.slice, nil]
        end

        params_node.optionals.each do |p|
          params << [p.name.to_s, p.value.slice]
        end

        if params_node.rest
          case params_node.rest.type
          when :rest_parameter_node
            name = params_node.rest.name ? params_node.rest.name.to_s : ""
            params << ["*#{name}", nil]
          when :forwarding_parameter_node
            params << ["...", nil]
          end
        end

        params_node.posts.each do |p|
          params << [p.slice, nil]
        end

        params_node.keywords.each do |p|
          name = "#{p.name}:"
          case p.type
          when :required_keyword_parameter_node
            params << [name, nil]
          when :optional_keyword_parameter_node
            params << [name, p.value.slice]
          end
        end

        if params_node.keyword_rest
          case params_node.keyword_rest.type
          when :keyword_rest_parameter_node
            if params_node.keyword_rest.name
              params << ["**#{params_node.keyword_rest.name}", nil]
            end
          when :forwarding_parameter_node
            params << ["...", nil]
          end
        end

        if params_node.block && !params_node.keyword_rest.is_a?(Prism::ForwardingParameterNode)
          params << ["&#{params_node.block.name}", nil]
        end

        params
      end

      def detect_struct_or_data(call_node)
        return nil unless call_node.is_a?(Prism::CallNode)
        return nil unless call_node.receiver

        recv = call_node.receiver
        name = call_node.name.to_s
        recv_name = resolve_path(recv)

        if recv_name == "Struct" && name == "new"
          { type: :struct, members: extract_symbols(call_node), block: call_node.block }
        elsif recv_name == "Data" && name == "define"
          { type: :data, members: extract_symbols(call_node), block: call_node.block }
        end
      end

      def create_struct_class(class_name, info, node)
        superclass = info[:type] == :struct ? "Struct" : "Data"
        klass = create_class(class_name, superclass)
        create_attributes(klass, info[:members])
        # Data.define creates read-only structs — remove writers
        if info[:type] == :data
          info[:members].each do |member|
            if (writer = klass.attributes[:instance][member][:write])
              klass.attributes[:instance][member][:write] = nil
              Registry.delete(writer)
            end
          end
        end
        klass
      end

      def evaluate_condition(node)
        case node.type
        when :true_node then true
        when :false_node then false
        when :nil_node then false
        when :integer_node then node.value != 0
        when :defined_node
          inner = node.value
          if constant_node?(inner)
            name = resolve_path(inner)
            obj = Registry.resolve(namespace, name, true)
            return true if obj && !obj.is_a?(Proxy)
            if name =~ /\A[A-Z_][A-Za-z0-9_]*(::[A-Z_][A-Za-z0-9_]*)*\z/
              begin
                return true if Object.const_defined?(name)
              rescue NameError
                nil
              end
            end
            return nil
          end
          nil
        else
          nil
        end
      end

      include Handlers::Common::MethodHandler

      def find_attached_macro(method_name)
        macros = Registry.all(:macro)
        return nil if macros.empty?
        tree = namespace.inheritance_tree(true)
        tree.push(P(namespace, 'Object')) unless tree.last&.path == 'Object'
        macros.each do |macro|
          next unless macro.method_object
          objs = [macro.method_object]
          if objs.first.type != :proxy && objs.first.respond_to?(:aliases)
            objs.concat(objs.first.aliases)
          end
          next unless objs.any? { |obj| obj.name.to_s == method_name.to_s }
          tree.each { |obj| return macro if obj == macro.method_object.namespace }
        end
        nil
      end

      IMPLICIT_DOCSTRING_RE = /^@!?(?:method|attribute|overload|visibility|scope|return)\b/
      VISIBILITY_DIRECTIVE_RE = /^\s*@!?visibility\s+(public|private|protected)\b/m

      def implicit_docstring?(comment)
        comment =~ IMPLICIT_DOCSTRING_RE
      end

      def dsl_method_name
        name = @current_call_params.first || ""
        if name =~ /^#{CodeObjects::METHODNAMEMATCH}$/
          name
        else
          nil
        end
      end

      def call_params_from(node)
        return [] unless node.arguments
        node.arguments.arguments.map { |arg| prism_arg_value(arg) }
      end

      # Extract a clean string value from a Prism argument node,
      # matching the behavior of Ripper's call_params (which jumps
      # to :ident or :tstring_content).
      def prism_arg_value(node)
        case node.type
        when :symbol_node then node.value.to_s
        when :string_node then node.content
        when :constant_read_node then node.name.to_s
        when :constant_path_node then resolve_path(node)
        when :integer_node then node.value.to_s
        when :float_node then node.value.to_s
        when :true_node then "true"
        when :false_node then "false"
        when :nil_node then "nil"
        else node.slice
        end
      end
    end if defined?(::Prism)
  end
end
