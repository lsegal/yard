# frozen_string_literal: true

# Handles classes
class YARD::Handlers::RBS::ConstantHandler < YARD::Handlers::RBS::Base
  handles ::RBS::AST::Declarations::Constant

  process do
    name = statement.name.to_s
    register ConstantObject.new(namespace, name) do |obj|
      obj.value = '?'
      return if obj.docstring.has_tag?(:return)
      obj.docstring.add_tag(YARD::Tags::Tag.new(:return, '', [statement.type.to_s]))
    end
  end
end
