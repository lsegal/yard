module YARD
  module Handlers
    module Ruby
      # Handles a macro (dsl-style method)
      class MacroHandler < Base
        include CodeObjects
        handles method_call
        namespace_only

        process do
          if statement.call? && statement.method_name(true).to_s =~ /\Aattr_(reader|writer|accessor)\Z/
            return # Ignore attr_*
          end

          @macro, @docstring = nil, Docstring.new(statement.comments)
          find_or_create_macro
          return if !@macro && !statement.comments_hash_flag && @docstring.tags.size == 0
          @docstring = expanded_macro_or_docstring
          @docstring.hash_flag = statement.comments_hash_flag
          @docstring.line_range = statement.comments_range
          name = method_name
          raise UndocumentableError, "method, missing name" if name.nil? || name.empty?
          tmp_scope = sanitize_scope
          tmp_vis = sanitize_visibility
          object = MethodObject.new(namespace, name, tmp_scope)
          register(object)
          object.visibility = tmp_vis
          object.dynamic = true
          object.docstring = @docstring
          object.signature = method_signature
          create_attribute_data(object)
        end

        private

        def call_params
          [statement.method_name(true)] +
            statement.parameters(false).map do |x|
              x.jump(:ident, :tstring_content).source
            end
        end

        def caller_method
          if statement.call?
            statement.method_name(true).to_s
          else
            statement[0].jump(:ident).source
          end
        end

        def find_or_create_macro
          if @docstring.tag(:macro)
            macro_name = @docstring.tag(:macro).name
            raise UndocumentableError, 'method/attribute, missing macro name' unless macro_name
            @macro = MacroObject.find_or_create(@docstring, P(namespace, caller_method))
            return if @macro
          end

          # Look for implicit macros
          Registry.all(:macro).each do |macro|
            next unless macro.attached?
            next unless macro.method_object.name == caller_method.to_sym
            namespace.inheritance_tree.each do |obj|
              ensure_loaded!(obj)
              break(@macro = macro) if obj == macro.method_object.namespace
            end
          end
        end
        
        def expanded_macro_or_docstring
          return @docstring unless @macro
          data = MacroObject.apply_macro(@macro, @docstring, call_params, statement.source)
          Docstring.new(data)
        end

        def create_attribute_data(object)
          return unless object.docstring.tag(:attribute)
          ensure_loaded!(namespace)
          clean_name = object.name.to_s.sub(/=$/, '')
          namespace.attributes[object.scope][clean_name] ||= SymbolHash[:read => nil, :write => nil]
          if attribute_readable?
            namespace.attributes[object.scope][clean_name][:read] = object
          end
          if attribute_writable?
            if object.name.to_s[-1,1] == '='
              writer = object
            else
              writer = MethodObject.new(namespace, object.name.to_s + '=', object.scope)
              register(writer)
              writer.signature = "def #{object.name}=(value)"
              writer.visibility = object.visibility
              writer.dynamic = true
            end
            namespace.attributes[object.scope][clean_name][:write] = writer
          end
        end

        def attribute_writable?
          if @docstring.tag(:attribute) 
            types = @docstring.tag(:attribute).types
            return types ? types.join.include?('w') : true
          end
          false
        end

        def attribute_readable?
          if @docstring.tag(:attribute) 
            types = @docstring.tag(:attribute).types
            return types ? (types.join =~ /(?<!w)r/ ? true : false) : true
          end
          false
        end

        def method_name
          name = nil
          [:method, :attribute, :overload].each do |tag|
            if @docstring.tag(tag)
              name = @docstring.tag(tag).send(tag == :method ? :name : :text)
              break
            end
          end
          name = nil if name =~ /\A\s*\Z/
          name ||= call_first_parameter
          return unless name
          if name =~ /\A\s*([^\(; \t]+)/
            name = $1
          end
          if @docstring.tag(:attribute) && !attribute_readable?
            name = name + '='
          end
          name
        end

        def method_signature
          if @docstring.tag(:method)
            name = @docstring.tag(:method).name
          elsif @docstring.tag(:overload)
            name = @docstring.tag(:overload).text
          elsif @docstring.tag(:attribute)
            name = @docstring.tag(:attribute).text
            name += '=(value)' if !attribute_readable?
          else
            name = method_name
          end
          name = nil if name =~ /\A\s*\Z/
          name ||= call_first_parameter
          name =~ /^def\b/ ? name : "def #{name}"
        end

        def call_first_parameter
          return nil unless statement.call?
          statement.parameters[0].jump(:ident, :tstring_content).source
        end

        def sanitize_scope
          tmp_scope = @docstring.tag(:scope) ? @docstring.tag(:scope).text : ''
          %w(class instance).include?(tmp_scope) ? tmp_scope.to_sym : scope
        end

        def sanitize_visibility
          vis = @docstring.tag(:visibility) ? @docstring.tag(:visibility).text : ''
          %w(public protected private).include?(vis) ? vis.to_sym : visibility
        end
      end
    end
  end
end
