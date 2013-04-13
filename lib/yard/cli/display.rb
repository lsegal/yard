module YARD
  module CLI
    # Display one object
    # @since 0.8.6
    class Display < Yardoc
      def description; 'Displays a formatted object' end

      def initialize(*args)
        super
        options.format = :text # default for this command
      end

      # Runs the commandline utility, parsing arguments and displaying an object
      # from the {Registry}.
      #
      # @param [Array<String>] args the list of arguments.
      # @return [void]
      def run(*args)
        return unless parse_arguments(*args)
        @objects.each do |obj|
          log.puts obj.format(options)
        end
      end

      # Parses commandline options.
      # @param [Array<String>] args each tokenized argument
      def parse_arguments(*args)
        opts = OptionParser.new
        opts.banner = "Usage: yard display [options] OBJECT [OTHER OBJECTS]"
        general_options(opts)
        output_options(opts)
        parse_options(opts, args)

        Registry.load
        @objects = args.map {|o| Registry.at(o) }

        # validation
        return false if @objects.any? {|o| o.nil? }
        verify_markup_options
      end
    end
  end
end
