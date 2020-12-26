# frozen_string_literal: true

# Handles modules
class YARD::Handlers::RBS::ModuleHandler < YARD::Handlers::RBS::Base
  handles ::RBS::AST::Declarations::Module
  handles ::RBS::AST::Declarations::Interface

  process do
    modname = statement.name.to_s
    register ModuleObject.new(namespace, modname) do |mod|
      if mod.name =~ /^_/
        mod.visibility = :private
        mod.add_tag(YARD::Tags::Tag.new(:private, ''))
      end

      parse_block(statement, :namespace => mod)
    end
  end
end
