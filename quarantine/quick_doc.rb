require File.dirname(__FILE__) + '/namespace'

module YARD
  class QuickDoc
    def initialize(name)
      Namespace.load
      if name.nil?
        puts "Method Listing:"
        puts "---------------"
        puts Namespace.all.select {|n| Namespace.at(n).is_a? MethodObject }.sort.join("\n") 
        return 
      end
      
      meth = Namespace.at(name)
      if meth.nil? 
        puts "No entry for #{name}"
        return
      end
      
      ns = meth.path
      rvalue = meth.tag('return')
      return_type = rvalue && rvalue.type ? rvalue.type : "undefined"
      block = nil
      unless meth.tags("yieldparam").empty?
        block = " {|" + meth.tags("yieldparam").collect {|tag| tag.name }.join(", ") + "| ... }"
      end
      
      puts "Documentation for #{ns}"
      puts "==================#{'=' * ns.length}"
      if meth.file
        puts "File: '#{meth.file}' (on line #{meth.line})"
      end
      puts "Type: #{return_type}\t\tVisibility: #{meth.visibility}"
      puts
      if meth.tag('deprecated')
        desc = meth.tag('deprecrated').text
        puts
        puts "!! This method is deprecated" + (desc ? ": #{desc}" : ".")
        puts
      end
      if meth.docstring
        puts word_wrap(meth.docstring, ns.length + 18)
        puts 
      end
      unless meth.tags("param").empty? && meth.tags("raise").empty? && meth.tags("return").empty?
        puts "Meta Tags:"
        puts "----------"
        meth.tags("param").each do |tag|
          types = tag.types.empty? ? "" : "[#{tag.types.join(", ")}] "
          puts "> Parameter: #{types}#{tag.name} => #{tag.text}"
        end
        meth.tags("raise").each do |tag|
          puts "> Raises #{tag.name} exception#{tag.text ? ': ' + tag.text : ''}"
        end
        meth.tags("return").each do |tag|
          puts "> Returns #{tag.types.empty? ? "" : "(as " + tag.types.join(", ") + ')'} #{tag.text}"
        end
        puts
        unless meth.tags("yieldparam").empty?
          puts "Yields:"
          puts "-------"
          meth.tags("yieldparam").each do |tag|
            types = tag.types.empty? ? "" : "[#{tag.types.join(", ")}] "
            puts "> Block parameter: #{types}#{tag.name} => #{tag.text}"
            puts
          end
        end
      end
      if meth.source
        puts "Definition:"
        puts "-----------"
        puts format_code(meth.source.sub("\n", "#{block}" + (return_type ? " # -> " + return_type : "") + "\n"))
        puts    
      end
      unless meth.tags("see").empty?
        puts "See Also:"
        puts "---------"
        meth.tags("see").each do |tag|
          puts "\t- #{tag.text}"
        end
        puts
      end
    end
    
    protected
      def word_wrap(text, length = 80)
        text.gsub(/(.{0,#{length - 3}}\s)/, "\n" + '\1')
      end

      def format_code(text, indent_size = 2)
        last_indent, tab = nil, 0
        text.split(/\r?\n/).collect do |line|
          indent = line[/^(\s*)/, 1].length
          if last_indent && indent > last_indent
            tab += indent_size
          elsif last_indent && indent < last_indent
            tab -= indent_size
          end
          last_indent = indent
          (" " * tab) + line.sub(/^\s*/, '')
        end.join("\n")
      end
  end
end