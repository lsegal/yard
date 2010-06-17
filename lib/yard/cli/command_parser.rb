module YARD
  module CLI
    class CommandParser
      class << self
        attr_accessor :commands
        attr_accessor :default_command
      end
      
      self.commands = SymbolHash[
        :doc    => Yardoc,
        :graph  => Graph,
        :ri     => YRI,
        :server => Server
      ]
      
      self.default_command = :doc
      
      def self.run(*args) new.run(*args) end
        
      def initialize
        log.show_backtraces = false
      end
            
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
      
      def commands; self.class.commands end
      
      private
      
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