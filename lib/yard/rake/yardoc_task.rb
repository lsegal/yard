require 'rake'
require 'rake/tasklib'

module YARD
  module Rake
    
    class YardocTask < ::Rake::TaskLib
      attr_accessor :name
      attr_accessor :options
      attr_accessor :files

      def initialize(name = :yardoc)
        @name = name
        @options = []
        @files = []
        
        yield self if block_given?
        define
      end
      
      def define
        task(name) { YARD::CLI::Yardoc.run *(options + files) }
      end
    end
  end
end