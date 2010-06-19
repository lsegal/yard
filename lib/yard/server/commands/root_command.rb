module YARD
  module Server
    module Commands
      class RootCommand < StaticFileCommand
        attr_accessor :projects
        
        def initialize(projects, base_uri, single)
          super(nil, nil, base_uri, single)
          self.projects = projects
        end
        
        def run
          return super unless path.empty?
          
          if single_project
            self.status, self.headers, self.body = 
              *DisplayObjectCommand.new(projects.keys.first, 
                projects.values.first, base_uri, single_project).call(request)
          else
            options.update(
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
end