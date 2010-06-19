module YARD
  module CLI
    # A local documentation server
    class Server < Command
      attr_accessor :single_project
      
      def description
        "Runs a local documentation server"
      end
      
      def run(*args)
        optparse(*args)
        YARD::Server::WebrickAdapter.start({'yard' => '.yardoc'}, 
          {:single_project => single_project}, {:Port => 8000})
      end
      
      private
      
      def optparse(*args)
        opts = OptionParser.new
        opts.on('--single-project', 'Documentation for a single project') do
          self.single_project = true
        end
        common_options(opts)
        parse_options(opts, args)
      end
    end
  end
end