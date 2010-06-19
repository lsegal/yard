module YARD
  module Server
    module Commands
      class RootCommand < StaticFileCommand
        attr_accessor :projects
        attr_accessor :options
        
        def run
          return super unless path.empty?
          
          self.options = SymbolHash.new(false).update(
            :markup => :rdoc,
            :format => :html,
            :projects => projects,
            :template => :doc_server,
            :type => :project_list
          )
          render
        end
      end
    end
  end
end