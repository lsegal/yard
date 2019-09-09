# frozen_string_literal: true
# Parses comments
class YARD::Handlers::C::OverrideCommentHandler < YARD::Handlers::C::Base
  handles(/./)
  statement_class Comment

  process do
    if statement.overrides.empty?
      register_docstring(nil) if directive_tag?
      return
    end
    statement.overrides.each do |type, name|
      override_comments << [name, statement]
      obj = nil
      case type
      when :class
        name, superclass = *name.split(/\s*<\s*/)
        obj = YARD::CodeObjects::ClassObject.new(:root, name)
        obj.superclass = "::#{superclass}" if superclass
      when :module
        obj = YARD::CodeObjects::ModuleObject.new(:root, name)
      end
      register(obj)
    end
  end

  def register_docstring(object, docstring = statement.source, stmt = statement)
    super
  end

  def register_file_info(object, file = parser.file, line = statement.line, comments = statement.comments)
    super
  end

  private

  def directive_tag?
    statement.source.start_with?('@!')
  end
end
