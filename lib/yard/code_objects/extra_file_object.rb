module YARD::CodeObjects
  # A ClassObject represents a Ruby class in source code. It is a {ModuleObject}
  # with extra inheritance semantics through the superclass.
  class ExtraFileObject
    attr_accessor :filename
    attr_accessor :attributes
    attr_accessor :name
    attr_accessor :contents
    
    def initialize(filename)
      self.filename = filename
      self.name = File.basename(filename).gsub(/\.[^.]+$/, '')
      self.attributes = SymbolHash.new(false)
      parse_contents
    end
    
    alias path name
    
    def title
      attributes[:title] || name
    end
    
    def inspect
      "#<yardoc extra_file #{filename} attrs=#{attributes.inspect}>"
    end
    alias to_s inspect
        
    private
    
    def parse_contents
      contents = File.readlines(@filename)
      cut_index = 0
      contents.each_with_index do |line, index|
        case line
        when /^#!(\S+)\s*$/
          if index == 0
            attributes[:markup] = $1
          else
            cut_index = index
            break
          end
        when /^\s*#\s*@(\S+)\s*(.+?)\s*$/
          attributes[$1] = $2
        else
          cut_index = index
          break
        end
      end
      contents = contents[cut_index..-1] if cut_index > 0
      self.contents = contents.join
    end
  end
end