module YARD
  module Parser
    module Ruby
      class AstNode < Array
        attr_accessor :type, :parent, :docstring, :file, :full_source, :source
        attr_accessor :source_start, :source_end, :line_start, :line_end
        alias line line_start
        alias comments docstring

        def initialize(type, arr, opts = {})
          super(arr)
          children.each {|child| child.parent = self }
          self.type = type
          self.line_end = opts[:line]
          self.source_start = opts[:char]
          @token = true if opts[:token]

          reset_line_info
        end

        def push(*args)
          super(*args)
          child_args = args.select {|e| self.class === e }
          child_args.each {|child| child.parent = self }
          reset_line_info(child_args)
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

        def insert_comments(comments)
          comments = comments.dup
          traverse do |node|
            comments.each.with_index do |c, i|
              next if c.empty? || node.line.nil?
              if node.line.between?(c.last, c.last + 2)
                comments.delete_at(i)
                node.docstring = c.first
                break
              end
            end
          end
        end

        private

        def reset_line_info(nodes = nil)
          if nodes.nil?
            nodes = children
            self.line_start = line_end
            self.source_end = source_start + (token? ? first.length : 0)
          end

          if nodes.size > 0
            nodes.each do |child|
              self.source_end = child.source_end if child.source_end > source_end
              self.source_start = child.source_start if child.source_start < source_start
              self.line_end = child.line_end if child.line_end > line_end
              self.line_start = child.line_start if child.line_start < line_start
            end
          end
        end
      end
    end
  end
end