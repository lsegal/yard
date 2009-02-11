require 'ripper'
require 'pp'

class Node < Array
  attr_reader :type
  
  def initialize(*args)
    @options = {}
    @options.merge!(args.pop) if Hash === args.last
    @type = args.shift if Symbol === args.first

    super([*args])
  end
  
  def pretty_print(q)
    objs = [*self]
    objs.unshift(type) if type
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
    typeinfo = type ? ':' + type.to_s + ', ' : ''
    's(' + typeinfo + self.map(&:inspect).join(", ") + ')'
  end
  
  def to_s(use_source = true, indent = 0, root = nil)
    root ||= self
    buf = ""
    use_nl = false
    if use_source
      if src = root[:source]
        src = root[:source].gsub(/\n/, "\n\t") if indent > 0
        buf << src
        if buf[-1] != "\n"
          buf << " "
          use_nl = true
        end
      end

      root.each do |node|
        buf << node.to_s(use_source, indent + 1) if Node === node
      end
      
      if [:def, :if, :while, :class].include? root.type
        buf << "#{use_nl ? "\n" : ""}end#{use_nl ? "\n" : ""}"
      end
    else
      traverse do |node|
        buf << handle(node[:type])
      end
    end
    buf
  end

  def delete(key)
    options.delete(key)
  end
  
  def []=(key, val)
    options[key] = val
  end
  
  def [](key)
    options[key]
  end
  
  def traverse
    nodes = [self]
    nodes.each.with_index do |node, index|
      yield node
      nodes.insert index+1, *node.select {|e| Node === e }
    end
  end
  
  def insert_comments(comments)
    traverse do |node|
      next unless Node === node
      
      comments.each.with_index do |c, i|
        next if c.empty? || node[:line].nil?
        if node[:line].between?(c.last, c.last + 2)
          
          comments.delete_at(i)
          node[:docstring] = c.first
          break
        end
      end
    end
    
    self
  end

  def insert_source(source)
    traverse do |node|
      next unless Node === node
      
      source.each.with_index do |c, i|
        next if c.empty? || node[:line].nil?
        next if node.type[0] == "@"
        if node[:line] == c.last
          
          source.delete_at(i)
          node[:source] = c.first unless c.first.empty?
          break
        end
      end
    end
    
    self
  end
  
  private

  attr_accessor :options
  attr_writer :type
end

class RipperSexp < Ripper
  class << self
    def kw(*kws)
      (@kws ||= []).push(*kws)
      @kws.each do |kw|
        module_eval(<<-eof, __FILE__, __LINE__ + 1)
          def on_#{kw}(*args)
            visit(:#{kw}, @tokens[:#{kw}].pop, *args)
          rescue => e
            raise e.class, "Visit failed at #{kw}: \#{e.message}", e.backtrace
          end
        eof
      end
    end
    
    def no_comment(*toks)
      (@no_comments ||= []).push(*toks)
    end
    
    def rename(from, to)
      module_eval(<<-eof, __FILE__, __LINE__ + 1) 
        def on_#{from}(*args) 
          visit(:#{to}, lineno, *args) 
        end
      eof
    end
  
    attr_reader :kws, :no_comments
  end
  
  def parse
    super.insert_comments(@comments).insert_source(@data)
  end

  def initialize(*args)
    super
    @comments = []
    @tokens = {}
    @data = []
  end
  
  private

  PARSER_EVENT_TABLE.each do |event, arity|
    if /_new\z/ =~ event.to_s and arity == 0
      module_eval(<<-End, __FILE__, __LINE__ + 1)
        def on_#{event}
          Node.new
        end
      End
    elsif /_add(_.+)?\z/ =~ event.to_s
      module_eval(<<-eof, __FILE__, __LINE__ + 1)
        def on_#{event}(list, item)
          list.push(item) unless Node === item && item.type == :void_stmt
          list
        end
      eof
    else
      module_eval(<<-eof, __FILE__, __LINE__ + 1)
        def on_#{event}(*args)
          visit(:#{event}, lineno, *args)
        end
      eof
    end
  end

  SCANNER_EVENTS.each do |event|
    module_eval(<<-eof, __FILE__, __LINE__ + 1)
      def on_#{event}(tok)
        visit_token(tok)
        visit(:@#{event}, lineno, tok)
      end
    eof
  end

  kw  :class, :alias, :arg_paren, :paren, :lambda,
      :do_block, :brace_block, :def, :begin, :rescue, :rescue_mod,
      :if, :if_mod, :else, :elsif, :case, :when, 
      :next, :break, :retry, :redo, :return, :throw, :catch,
      :until, :until_mod, :while, :while_mod, :yield, :yield0, :zsuper,
      :unless, :unless_mod, :for, :super, :return0
      
  no_comment  :aref, :aref_field, :arg_paren, :brace_block, :do_block,
              :dot2, :dot3, :excessed_comma, :params, :paren, :sclass,
              :args_add_block, :string_literal, :binary, :string_content,
              :void_stmt, :stmt_body, :var_ref, :args, :self, :string_embexpr,
              :string_dvar, :xstring_literal, :rest_param, :blockarg
              
  rename :fcall, :call
  rename :command, :call
  rename :command_call, :call
  
  def visit(node, line = nil, *args)
    line ||= lineno
    line = args.first[:line] if node == :call
    
    opts = { line: line }
    opts.delete_if {|k,v| v.nil? }
    
    Node.new(node, *args, opts)
  end
  
  def visit_token(node)
    return if (@data.empty? || @data.last.first.empty?) && node =~ /\A[ \t]+\Z/
    @seen_nsp = true if node[0] != "#" && node !~ /\A[ \t]+\Z/
    add_data(node)
    @last_token = node
  end
  
  def add_data(data)
    return if data == "end" || data == "}"
    if @data.empty? || @data.last.empty? || @new_stmt
      @data.push ["", lineno]
      @new_stmt = false
    end
    
    return if data =~ /\A\s+\Z/ && @data.last.first.empty?
    @data.last.first << data 
  end
  
  def on_string_literal(*args)
    if Node === args.first && args.first.type == :string_content
      args = args.first.map {|a| a }
    end
    visit(:string_literal, lineno, *args)
  end
  
  def on_program(prog)
    prog
  end
  
  def on_body_stmt(*args)
    args.first
  end
  
  def on_def(*args)
    visit(:def, @tokens[:def].pop, *args)
  end

  def on_do_block(*args)
    visit(:do_bock, @tokens[:do].pop, *args)
  end
  
  def on_brace_block(*args)
    visit(:brace_block, @tokens[:lbrace].pop, *args)
  end

  def on_paren(*args)
    visit(:paren, @tokens[:lparen].pop, *args)
  end

  def on_arg_paren(*args)
    visit(:arg_paren, @tokens[:lparen].pop, *args)
  end
  
  def on_call(*args)
    visit(:call, args.first[:line], *args)
  end
  
  def on_args_add(*args)
    args.shift
    visit(:args, lineno, *args)
  end
  
  def on_comment(comment)
    visit_token(comment)

    append_comment = false
    if @comments.size > 0 && @comments.last[2] == lineno - 1
      append_comment = true
      
      unless @last_seen_nsp && !@seen_nsp && column == @comments.last[1]
        append_comment = false
      end
    end
    
    if append_comment
      @comments.last.first.push(comment[1..-1])
    else
      @comments << [[comment[1..-1]], column, lineno]
    end
    @last_seen_nsp, @seen_nsp = @seen_nsp, false
  end
  
  def on_kw(token)
    (@tokens[token.to_sym] ||= []) << lineno
    visit_token(token)
    visit(:@kw, lineno, token)
    @new_stmt = true if token == "then"
  end
  
  def on_lparen(token)
    (@tokens[:lparen] ||= []) << lineno
    visit_token(token)
    visit(:@lparen, lineno)
  end
  
  def on_lbrace(token)
    (@tokens[:lbrace] ||= []) << lineno
    visit_token(token)
    visit(:@lbrace, lineno)
    @new_stmt = true
  end
  
  def on_ignored_nl(token)
    @last_seen_nsp, @seen_nsp = @seen_nsp, false
    new_stmt = true if @last_token == ";"
    visit_token(token)
    visit(:@ignored_nl, lineno)
    @new_stmt = true if new_stmt
  end
  
  def on_semicolon(token)
    visit_token(token)
    visit(:@semicolon, lineno)
    @new_stmt = true
  end
  
  def on_nl(token)
    @last_seen_nsp, @seen_nsp = @seen_nsp, false
    visit_token(token)
    visit(:@nl, lineno)
    @new_stmt = true
  end
end

p = RipperSexp.parse(<<-"eof")
  class X < END
    def m(x=2); end
    if 2 then      hi;
      bye
     end
  end
eof

pp p

puts p.to_s
