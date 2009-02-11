# encoding: utf-8
require 'ripper'
require 'pp'

class ASTNode
  attr_accessor :line, :docstring, :node, :children
  
  def initialize(node, opts = {})
    self.node = node
    self.line = opts[:line]
    self.children = [opts[:children]].flatten
    self.docstring = opts[:docstring]
  end

  def pretty_print(q)
    q.group(1, 's(', ')') do
      q.seplist([node, *children]) {|v| q.pp v }
    end
  end
  
  def inspect
    's(' + [node, *children].compact.map {|s| s.inspect }.join(", ") + ')'
  end
end

class RipperParser < Ripper
  def self.ignore(*nodes)
    nodes.each {|node| class_eval "def on_#{node}(*args) args end" }
  end
  
  def self.rename(from, to)
    class_eval "def on_#{from}(*args) visit(#{to.inspect}, *args) end"
  end
  
  PARSER_EVENTS.each {|e| class_eval "def on_#{e}(*args) visit(#{e.inspect}, *args) end" }
  
#  ignore :program, :stmts_add, :stmts_new, :string_add, :string_content, :args_add_block, :args_add, :args_new

  rename :body_stmt, :block
  rename :program, :stmts
  rename :const_ref, :const
  rename :const_field, :const
  rename :const_path_ref, :const_path
  rename :const_path_field, :const_path
  rename :var_ref, :var
  rename :var_field, :var

  def initialize(src, *args)
    super(src, *args)
    @comments = []
  end
  
  private

  def visit(node, *args)
    min_line = args.select {|n| ASTNode === n }.map {|n| n.line }.min 
    line = min_line || lineno
    
    ASTNode.new node, line: line, 
                      docstring: get_comments(line), 
                      children: args
  end

  def get_comments(line)
    if @comments.size > 0 
      @comments.each do |comment|
        if ((line-2)...line).include?(comment.last)
          @comments = []
          return comment.first
        end
      end
    end
  end
  
  def on_stmts_add(*args)
    if ASTNode === args.first 
      if args.first.node == :stmts_add
        return args.first.children[1..-1]
      elsif args.first.node == :stmts
        return args
      elsif args.first.node == :stmts_new
        args.shift
      end
    end
    
    args
  end
  
  def on_args_add(*args) 
    if ASTNode === args.first 
      if args.first.node == :args_add
        return args.first.children[1..-1]
      elsif args.first.node == :args
        return args
      elsif args.first.node == :args_new
        args.shift
      end
    end
    
    args
  end
  
#  def on_args_add_block(*args)
#    visit(:args, args.first)
#  end
  
  def on_arg_paren(*args) args[0] end
  
  def on_def(meth_name, params, block)
    visit(:def, meth_name, params, block)
  end
  
  def on_body_stmt(*args, a, b, c)
    args
  end
  
#  def on_block_var(*args) args[0] end
  
#  def on_string_add(*args) args[1] end
#  def on_method_add_block(*args) args[0] end
#  def on_method_add_arg(*args) args.first.children.push(*args[1..-1]); args.first end

  def on_comment(*args)
    if @comments.size > 0 && @comments.last[1] == lineno - 1
      @comments[-1] = [@comments.last.first + args.first + "\n", lineno]
    else
      @comments << [args.first + "\n", lineno]
    end
  end
end



=begin
Ripper::PARSER_EVENT_TABLE.each do |event, arity|
  puts "def on_#{event}#{arity == 0 ? "" : '('+%w[a b c d e f][0, arity].join(', ')+')'}"
  puts "  debug(:#{event}#{arity == 0 ? "" : ", " + %w[a b c d e f][0, arity].join(', ')})"
  puts "  [:#{event}#{arity == 0 ? "" : ", " + %w[a b c d e f][0, arity].join(', ')}]"
  puts "end\n\n"
end
=end