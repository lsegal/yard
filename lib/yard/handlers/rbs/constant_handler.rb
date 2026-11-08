# frozen_string_literal: true
# Handles RBS constant declarations: `Name: Type`, and class and module
# aliases: `class Name = Other`, `module Name = Other`
class YARD::Handlers::RBS::ConstantHandler < YARD::Handlers::RBS::Base
  handles :constant

  process do
    obj = register ConstantObject.new(namespace, statement.name)
    obj.value = statement.value if statement.value
    if statement.attr_rbs_type && !obj.has_tag?(:return)
      obj.add_tag YARD::Tags::Tag.new(:return, '', rbs_types(statement.attr_rbs_type))
    end
  end

  private

  def rbs_types(type_str)
    YARD::Handlers::RBS::MethodHandler.rbs_type_to_yard_types(type_str)
  end
end
