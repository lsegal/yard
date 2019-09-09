# frozen_string_literal: true
class YARD::Handlers::C::DirectiveParserHandler < YARD::Handlers::C::Base
  handles(/./)
  statement_class Comment

  process do
    Docstring.parser.parse(statement.source, namespace, self)
  end
end
