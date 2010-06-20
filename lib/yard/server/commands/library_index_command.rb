module YARD
  module Server
    module Commands
      class LibraryIndexCommand < StaticFileCommand
        attr_accessor :libraries
        attr_accessor :options
        
        def run
          return super unless path.empty?
          
          self.options = SymbolHash.new(false).update(
            :markup => :rdoc,
            :format => :html,
            :libraries => libraries,
            :template => :doc_server,
            :type => :library_list
          )
          render
        end
      end
    end
  end
end