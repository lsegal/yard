# frozen_string_literal: true
begin
  require 'rbs'
rescue LoadError; end

module YARD
  module Parser
    module RBS
      class RBSParser < Base
        def initialize(source, filename)
          @buffer = ::RBS::Buffer.new(:name => filename, :content => source)
          @signatures = []
        end

        def parse
          @signatures = ::RBS::Parser.parse_signature(@buffer)
        end

        def enumerator
          @signatures
        end
      end
    end
  end
end
