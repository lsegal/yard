module YARD
  module Handlers
    module C
      module HandlerMethods
        include Parser::C
        
        def handle_class(var_name, class_name, parent, in_module = nil)
          parent = nil if parent == "0"
          namespace = in_module ? namespace_for_variable(in_module) : YARD::Registry.root
          register CodeObjects::ClassObject.new(namespace, class_name) do |obj|
            obj.superclass = namespace_for_variable(parent) if parent
            namespaces[var_name] = obj
          end
        end
        
        def handle_module(var_name, module_name, in_module = nil)
          namespace = in_module ? namespace_for_variable(in_module) : YARD::Registry.root
          register CodeObjects::ModuleObject.new(namespace, module_name) do |obj|
            namespaces[var_name] = obj
          end
        end
        
        def handle_method(scope, var_name, name, func_name, source_file = nil)
          visibility = :public
          case scope
          when "singleton_method", "module_function"; scope = :class
          when "private_method"; scope = :instance; visibility = :private
          else; scope = :instance
          end

          namespace = namespace_for_variable(var_name)
          register CodeObjects::MethodObject.new(namespace, name, scope) do |obj|
            obj.visibility = visibility
            find_method_body(obj, func_name)
            obj.docstring.add_tag(YARD::Tags::Tag.new(:return, '', 'Boolean')) if name =~ /\?$/
          end
        end

        def handle_attribute(var_name, name, read, write)
          values = {:read => read.to_i, :write => write.to_i}
          {:read => name, :write => "#{name}="}.each do |type, meth_name|
            next unless values[type] > 0
            obj = handle_method(:instance, var_name, meth_name, nil)
            obj.namespace.attributes[:instance][name] ||= SymbolHash[:read => nil, :write => nil]
            obj.namespace.attributes[:instance][name][type] = obj
          end
        end
        
        def handle_alias(var_name, new_name, old_name)
          namespace = namespace_for_variable(var_name)
          new_meth, old_meth = new_name.to_sym, old_name.to_sym
          old_obj = namespace.child(:name => old_meth, :scope => :instance)
          new_obj = register CodeObjects::MethodObject.new(namespace, new_meth, :instance) do |o|
            o.visibility = visibility
          end

          if old_obj
            new_obj.signature = old_obj.signature
            new_obj.source = old_obj.source
            new_obj.docstring = old_obj.docstring
            new_obj.docstring.object = new_obj
          else
            new_obj.signature = "def #{new_meth}" # this is all we know.
          end

          namespace.aliases[new_obj] = old_meth
        end
        
        def handle_constants(type, var_name, const_name, value)
          return unless type == 'const'
          namespace = namespace_for_variable(var_name)
          register CodeObjects::ConstantObject.new(namespace, const_name) do |obj|
            obj.source_type = :c
            obj.value = value
            find_constant_docstring(obj)
          end
        end
        
        private
        
        def find_constant_docstring(object)
          comment = nil
          
          # found source (possibly) but no docstring
          # so look in overrides
          override_comments.each do |name, override_comment|
            next unless override_comment.file == statement.file
            just_const_name = name.gsub(/\A.+::/, '')
            if object.path == name || object.name.to_s == just_const_name
              comment = override_comment.source
              break
            end
          end

          # use any comments on this statement as a last resort
          if comment.nil? && statement.comments && statement.comments.source =~ /\S/
            object.docstring = statement.comments.source
          end
          
          # In the case of rb_define_const, the definition and comment are in
          # "/* definition: comment */" form.  The literal ':' and '\' characters
          # can be escaped with a backslash.
          if comment
            elements = comment.split(':')
            new_definition = elements[0..-2].join(':')
            if !new_definition.empty? then # Default to literal C definition
              new_definition.gsub!("\:", ":")
              new_definition.gsub!("\\", '\\')
            end
            new_definition.sub!(/\A(\s+)/, '')
            comment = $1.nil? ? elements.last : "#{$1}#{elements.last.lstrip}"
            object.value = new_definition
            object.docstring = comment
          end
        end

        def find_method_body(object, symbol)
          file, in_file = statement.file, false
          if statement.comments && statement.comments.source =~ /\A\s*in (\S+)\Z/
            file, in_file = $1, true
            process_file(file, object)
          end

          if src_stmt = symbols[symbol]
            object.files.replace([src_stmt.file, src_stmt.line])
            object.source = src_stmt.source
            unless src_stmt.comments.nil? || src_stmt.comments.source.empty?
              object.docstring = src_stmt.comments.source
              return # found docstring
            end
          end

          # found source (possibly) but no docstring
          # so look in overrides
          override_comments.each do |name, override_comment|
            next unless override_comment.file == file
            name = name.gsub(/::([^:]+?)\Z/, '.\1')
            just_method_name = name.gsub(/\A.+(#|::|\.)/, '')
            just_method_name = 'initialize' if just_method_name == 'new'
            if object.path == name || object.name.to_s == just_method_name
              object.docstring = override_comment.source
              return
            end
          end

          # use any comments on this statement as a last resort
          if !in_file && statement.comments && statement.comments.source =~ /\S/
            object.docstring = statement.comments.source
          end
        end
      end
    end
  end
end
