module YARD
  module Handlers
    module Ruby
      module Legacy
        # (see Ruby::MacroHandler)
        class MacroHandler < Base
          include CodeObjects
          include MacroHandlerMethods
          handles TkIDENTIFIER
          namespace_only

          process do
            return if namespace == Registry.root
            globals.__attached_macros ||= {}
            if !globals.__attached_macros[caller_method]
              return if Ruby::MacroHandler::IGNORE_METHODS[caller_method]
              return if !statement.comments || statement.comments.empty?
            end

            comments = statement.comments ? statement.comments.join("\n") : ""
            @macro, @docstring = nil, Docstring.new(comments)
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
            tokval_list(statement.tokens[1..-1], :attr, :identifier, TkId).map do |value|
              value.to_s
            end
          end

          def caller_method
            statement.tokens.first.text
          end
        end
      end
    end
  end
end
