module YARD
  module Parser
    module Ruby
      def s(*args)
        type = Symbol === args.first ? args.shift : :list
        opts = Hash === args.last ? args.pop : {}
        AstNode.new(type, args, opts)
      end
      
      class AstNode < Array
        attr_accessor :type, :parent, :docstring, :file, :full_source, :source
        attr_accessor :source_start, :source_end, :line_start, :line_end
        alias line line_start
        alias comments docstring
        alias to_s source
        
        KEYWORDS = { :class => true, :alias => true, :lambda => true, :do_block => true,
          :def => true, :begin => true, :rescue => true, :rescue_mod => true,
          :if => true, :if_mod => true, :else => true, :elsif => true,
          :case => true, :when => true, :next => true, :break => true,
          :retry => true, :redo => true, :return => true, :throw => true,
          :catch => true, :until => true, :until_mod => true, :while => true, :while_mod => true,
          :yield => true, :yield0 => true, :zsuper => true, :unless => true, :unless_mod => true,
          :for => true, :super => true, :return0 => true }

        def initialize(type, arr, opts = {})
          super(arr)
          self.type = type
          self.line_end = opts[:line]
          self.source_start = opts[:char]
          @token = true if opts[:token]
        end
        
        def ==(ast)
          super && type == ast.type
        end
        
        def show
          "\t#{line}: #{first_line}"
        end
        
        def first_line
          full_source.split(/\r?\n/)[line_start - 1].strip
        end
        
        def jump(*node_types)
          traverse {|child| return(child) if node_types.include?(child.type) }
          self
        end

        def children
          @children ||= select {|e| AstNode === e }
        end

        def token?
          @token
        end
        
        def ref?
          false
        end
        
        def literal?
          type =~ /_literal$/ ? true : false
        end
        
        def kw?
          KEYWORDS.has_key?(type)
        end
        
        def call?
          false
        end
        
        def condition?
          false
        end

        def file
          return parent.file if parent
          @file
        end

        def full_source
          return parent.full_source if parent
          return @full_source if @full_source
          return IO.read(@file) if file && File.exist?(file)
        end

        def source
          return parent.full_source[source_range] if parent
          full_source
        end

        def source_range
          Range.new(source_start, source_end)
        end

        def line_range
          Range.new(line_start, line_end)
        end

        def pretty_print(q)
          options = { docstring: docstring, source: source_range, line: line_range }
          options.delete_if {|k, v| v.nil? }
          objs = [*self]
          objs.unshift(type) if type && type != :list
          objs.push(options) if options.size > 0

          q.group(3, 's(', ')') do
            q.seplist(objs, nil, :each) do |v| 
              if v.object_id == options.object_id
                q.seplist(options, nil, :each) do |k, v| 
                  q.group(3) do 
                    q.text k
                    q.group(3) do 
                      q.text ': '
                      q.pp v 
                    end
                  end
                end
              else
                q.pp v 
              end
            end
          end
        end

        def inspect 
          typeinfo = type && type != :list ? ':' + type.to_s + ', ' : ''
          's(' + typeinfo + map(&:inspect).join(", ") + ')'
        end

        def traverse
          nodes = [self]
          nodes.each.with_index do |node, index|
            yield node
            nodes.insert index+1, *node.children
          end
        end

        def reset_line_info
          self.line_start = line_end
          self.source_end = source_start + (token? ? first.length - 1 : 0)

          if children.size > 0
            f, l = children.first, children.last
            self.source_start = f.source_start if f.source_start < source_start
            self.source_end = l.source_end if l.source_end > source_end
            self.line_start = f.line_start if f.line_start < line_start
            self.line_end = l.line_end if l.line_end > line_end

            adjust_start_and_end(f, l)
          end
        end
        
        private
        
        def adjust_start_and_end(f, l)
          case type
          when :list
            self.source_end = l.source_end if l
          when :var_ref, :var_field, :const_ref
            self.source_end = self.source_start + f.first.length - 1
          when :top_const_ref
            self.source_end = self.source_start + f.first.length - 1
            self.source_start -= 2
          when :const_path_ref
            self.source_end = l.source_end
          else
            self.source_start -= type.to_s.length + 1 if kw?
            self.source_end -= 1 if call?
            if literal?
              self.source_start -= 1
              self.source_end   -= 1
            end
          end
        end
      end
      
      class ReferenceNode < AstNode
        def ref?; true end
        
        def path
          Array.new flatten
        end
        
        def namespace
          Array.new flatten[0...-1]
        end
        
        def source
          super.split(/\s+/).first
        end
      end
      
      class ParameterNode < AstNode
        def required_params; self[0] end
        def required_end_params; self[4] end
        def optional_params; self[1] end
        def splat_param; self[2] ? self[2][0] : nil end
        def block_param; self[4] ? self[4][0] : nil end
      end
      
      class MethodCallNode < AstNode
        def call?; true end
        def namespace; first if index_adjust > 0 end

        def method_name(name_only = false)
          name = self[index_adjust]
          name_only ? name.jump(:ident).first.to_sym : name
        end

        def parameters(include_block_param = true)
          params = self[1 + index_adjust]
          params = call_has_paren? ? params.first : params
          include_block_param ? params : params[0...-1]
        end
        
        def block_param; parameters.last end
        
        private
        
        def index_adjust
          [:call, :command_call].include?(type) ? 2 : 0
        end
        
        def call_has_paren? 
          [:fcall, :call].include?(type)
        end
      end
      
      class ConditionalNode < AstNode
        def condition?; true end
        def condition; first end
        def then_block; self[1] end
        
        def else_block
          if self[2] && !cmod?
            self[2].type == :elsif ? self[2] : self[2][0]
          end
        end
        
        private
        
        def cmod?; type =~ /_mod$/ end
      end
    end
  end
end