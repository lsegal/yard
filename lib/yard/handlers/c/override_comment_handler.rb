# Parses comments
class YARD::Handlers::C::OverrideCommentHandler < YARD::Handlers::C::Base
  handles %r{.}
  statement_class Comment
  
  process do
    return if statement.overrides.empty?
    statement.overrides.each do |type, name|
      override_comments << [name, statement]
      obj = nil
      case type
      when :class
        obj = CodeObjects::ClassObject.new(:root, name)
      when :module
        obj = CodeObjects::ModuleObject.new(:root, name)
      end
      obj.docstring = statement.source if obj
    end
  end
end
