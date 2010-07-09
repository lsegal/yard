module YARD
  module Server
    module Commands
      class FramesCommand < DisplayObjectCommand
        include DocServerHelper
        
        def run
          main_url = "#{base_path.gsub(/frames$/, '')}#{object_path}"
          if path && !path.empty?
            page_title = "Object: #{object_path}"
          elsif options[:files] && options[:files].size > 0
            page_title = "File: #{options[:files].first.sub(/^#{library_path}\/?/, '')}"
            main_url = url_for_file(options[:files].first)
          elsif !path || path.empty?
            page_title = "Documentation for #{library.name} #{library.version ? '(' + library.version + ')' : ''}"
          end

          options.update(
            :page_title => page_title,
            :main_url => main_url,
            :template => :doc_server,
            :type => :frames
          )
          render
        end
      end
    end
  end
end
