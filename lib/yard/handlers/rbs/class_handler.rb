# frozen_string_literal: true

# Handles classes
class YARD::Handlers::RBS::ClassHandler < YARD::Handlers::RBS::Base
  handles ::RBS::AST::Declarations::Class

  process do
    klassname = statement.name.to_s
    register ClassObject.new(namespace, klassname) do |klass|
      if klass.name =~ /^_/
        klass.visibility = :private
        klass.add_tag(YARD::Tags::Tag.new(:private, ''))
      end

      if statement.super_class
        klass.superclass = P(namespace, statement.super_class.name.to_s)
      end
      parse_block(statement, :namespace => klass)
    end
  end
end
