require 'rake'
require 'rake/tasklib'

module YARD
  module Rake
    
    class YardocTask < ::Rake::TaskLib
      attr_accessor :name
      attr_accessor :options
      attr_accessor :files
      attr_accessor :before, :after

      def initialize(name = :yard)
        @name = name
        @options = []
        @files = []
        
        yield self if block_given?
        self.options +=  ENV['OPTS'].split(/[ ,]/) if ENV['OPTS'] 
        self.files   += ENV['FILES'].split(/[ ,]/) if ENV['FILES']
        
        define
      end
      
      def define
        desc "Generate YARD Documentation"
        task(name) do
          before.call if before.is_a?(Proc)
          YARD::CLI::Yardoc.run *(options + files) 
          after.call if after.is_a?(Proc)
        end
      end
    end
  end
end