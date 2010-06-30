module YARD
  module CLI
    class CommandParser
      class << self
        attr_accessor :commands
        attr_accessor :default_command
      end
      
      self.commands = SymbolHash[
        :diff   => Diff,
        :doc    => Yardoc,
        :gems   => Gems,
        :graph  => Graph,
        :help   => Help,
        :ri     => YRI,
        :server => Server,
        :stats  => Stats
      ]
      
      self.default_command = :doc
      
      # Convenience method to create a new CommandParser and call {#run}
      # @return (see #run)
      def self.run(*args) new.run(*args) end
        
      def initialize
        log.show_backtraces = false
      end
           
      # Runs the {Command} object matching the command name of the first
      # argument.
      # @return [void] 
      def run(*args)
        unless args == ['--help']
          if args.size == 0 || args.first =~ /^-/
            command_name = self.class.default_command
          else
            command_name = args.first.to_sym
            args.shift
          end
          if commands.has_key?(command_name)
            return commands[command_name].run(*args)
          end
        end
        list_commands
      end
      
      private

      def commands; self.class.commands end
      
      def list_commands
        puts "Usage: yard <command> [options]"
        puts
        puts "Commands:"
        commands.keys.sort_by {|k| k.to_s }.each do |command_name|
          command = commands[command_name].new
          puts "%-8s %s" % [command_name, command.description] 
        end
      end
    end
  end
end