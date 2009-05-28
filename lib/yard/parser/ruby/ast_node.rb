module YARD
  module Parser
    module Ruby
      def s(*args)
        type = Symbol === args.first ? args.shift : :list
        opts = Hash === args.last ? args.pop : {}
        AstNode.node_class_for(type).new(type, args, opts)
      end
      
      class AstNode < Array
        attr_accessor :type, :parent, :docstring, :file, :full_source, :source
        attr_accessor :source_range, :line_range
        alias comments docstring
        alias to_s source
        
        KEYWORDS = { class: true, alias: true, lambda: true, do_block: true,
          def: true, defs: true, begin: true, rescue: true, rescue_mod: true,
          if: true, if_mod: true, else: true, elsif: true, case: true,
          when: true, next: true, break: true, retry: true, redo: true,
          return: true, throw: true, catch: true, until: true, until_mod: true,
          while: true, while_mod: true, yield: true, yield0: true, zsuper: true,
          unless: true, unless_mod: true, for: true, super: true, return0: true }
        
        def self.node_class_for(type)
          case type
          when :params
            ParameterNode
          when :call, :fcall, :command, :command_call
            MethodCallNode
          when :if, :elsif, :if_mod, :unless, :unless_mod
            ConditionalNode
          when /_ref\Z/
            ReferenceNode
          else
            AstNode
          end
        end

        def initialize(type, arr, opts = {})
          super(arr)
          self.type = type
          self.line_range = opts[:line]
          self.source_range = opts[:char]
          @fallback_line = opts[:listline]
          @fallback_source = opts[:listchar]
          @token = true if opts[:token]
        end
        
        def ==(ast)
          super && type == ast.type
        end
        
        def show
          "\t#{line}: #{first_line}"
        end
        
        def source_range
          reset_line_info unless @source_range
          @source_range
        end
        
        def line_range
          reset_line_info unless @line_range
          @line_range
        end
        
        def has_line?
          @line_range ? true : false
        end
        
        def line
          line_range && line_range.first
        end
        
        def first_line
          full_source.split(/\r?\n/)[line - 1].strip
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

        def pretty_print(q)
          objs = [*self.dup, :__last__]
          objs.unshift(type) if type && type != :list

          options = {}
          if @docstring
            options[:docstring] = docstring
          end
          if @source_range || @line_range
            options[:line] = line_range
            options[:source] = source_range
          end
          objs.pop if options.size == 0

          q.group(3, 's(', ')') do
            q.seplist(objs, nil, :each) do |v| 
              if v == :__last__
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
        
        private

        def reset_line_info
          if size == 0
            self.line_range = @fallback_line
            self.source_range = @fallback_source
          elsif children.size > 0
            f, l = children.first, children.last
            self.line_range = Range.new(f.line_range.first, l.line_range.last)
            self.source_range = Range.new(f.source_range.first, l.source_range.last)
          elsif @fallback_line || @fallback_source
            self.line_range = @fallback_line
            self.source_range = @fallback_source
          else
            self.line_range = 0...0
            self.source_range = 0...0
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
        def required_end_params; self[3] end
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