module YARD
  module Parser
    module Ruby
      def s(*args)
        type = Symbol === args.first ? args.shift : :list
        opts = Hash === args.last ? args.pop : {}
        AstNode.new(type, args, opts)
      end
      
      module ReferenceNode
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
      
      module ParameterNode
        def required_params; self[0] end
        def required_end_params; self[4] end
        def optional_params; self[1] end
        def splat_param; self[2] ? self[2][0] : nil end
        def block_param; self[4] ? self[4][0] : nil end
      end
      
      class AstNode < Array
        attr_accessor :type, :parent, :docstring, :file, :full_source, :source
        attr_accessor :source_start, :source_end, :line_start, :line_end
        alias line line_start
        alias comments docstring
        alias to_s source

        def initialize(type, arr, opts = {})
          super(arr)
          children.each {|child| child.parent = self }
          self.type = type
          self.line_end = opts[:line]
          self.source_start = opts[:char]
          @token = true if opts[:token]

          reset_line_info
          mixin_type_methods
        end

        def push(*args)
          super(*args)
          child_args = args.select {|e| self.class === e }
          child_args.each {|child| child.parent = self }
          reset_line_info(child_args)
        end
        
        def show
          text = full_source.split(/\r?\n/)[line_start - 1].strip
          "\t#{line}: #{text}"
        end
        
        def jump(node_type)
          traverse {|child| return(child) if child.type == node_type }
          self
        end

        def first_child
          find {|e| self.class === e }
        end

        def children
          select {|e| self.class === e }
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
          [:class, :alias, :lambda, :do_block, :def, :begin, :rescue, 
           :rescue_mod, :if, :if_mod, :else, :elsif, :case, :when, 
           :next, :break, :retry, :redo, :return, :throw, :catch,
           :until, :until_mod, :while, :while_mod, :yield, :yield0, :zsuper,
           :unless, :unless_mod, :for, :super, :return0].include?(type)
        end
        
        def call?
          [:call, :fcall, :command, :command_call].include?(type)
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

        private
        
        def mixin_type_methods
          case type
          when /_ref\z/
            extend ReferenceNode
          when :params
            extend ParameterNode
          end
        end

        def reset_line_info(nodes = nil)
          return if source_start.nil? || line_end.nil?
          if nodes.nil?
            nodes = children
            self.line_start = line_end
            self.source_end = source_start + (token? ? first.length - 1 : 0)
          end

          if nodes.size > 0
            nodes.each do |child|
              self.source_end = child.source_end if child.source_end > source_end
              self.source_start = child.source_start if child.source_start < source_start
              self.line_end = child.line_end if child.line_end > line_end
              self.line_start = child.line_start if child.line_start < line_start
            end
          end
          
          adjust_start_and_end
        end
        
        def adjust_start_and_end
          case type
          when :var_ref, :var_field, :const_ref, :const_path_ref
            self.source_end = self.source_start + children.first.first.length - 1
          else
            self.source_start -= type.to_s.length if kw?
            self.source_end -= 1 if call?
            if literal?
              self.source_start -= 1 
              self.source_end   -= 1
            end
          end
        end
      end
    end
  end
end