module YARD
  module Server
    module Commands
      class LibraryIndexCommand < Base
        attr_accessor :options
        
        def run
          return unless path.empty?
          
          self.options = SymbolHash.new(false).update(
            :markup => :rdoc,
            :format => :html,
            :libraries => adapter.libraries,
            :adapter => adapter,
            :template => :doc_server,
            :type => :library_list
          )
          render
        end
      end
    end
  end
end