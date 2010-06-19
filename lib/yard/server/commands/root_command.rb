module YARD
  module Server
    module Commands
      class RootCommand < StaticFileCommand
        attr_accessor :projects
        
        def run
          return super unless path.empty?
          
          if single_project
            self.status, self.headers, self.body = 
              *DisplayObjectCommand.new(command_options).call(request)
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