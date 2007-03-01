class YARD::MethodHandler < YARD::CodeObjectHandler
  handles RubyToken::TkDEF
  
  def process
    stmt_nospace = statement.tokens.reject {|t| t.is_a? RubyToken::TkSPACE }
    method_name, method_scope = stmt_nospace[1].text, current_scope
    holding_object = object
    
    # Use the third token (after the period) if statement begins with a "Constant." or "self."
    if [RubyToken::TkCOLON2,RubyToken::TkDOT].include?(stmt_nospace[2].class)
      method_class = stmt_nospace[1].text
      holding_object = YARD::Namespace.find_from_path(object.path, method_class)
      holding_object = YARD::Namespace.find_or_create_namespace(method_class) if holding_object.nil?
      method_name = stmt_nospace[3..-1].to_s[/\A(.+?)(?:\(|;|$)/,1]
      method_scope = :class
    end
  
    method_object = YARD::MethodObject.new(method_name, current_visibility, 
                                           method_scope, holding_object, statement.comments)
    enter_namespace(method_object) do |obj|
      #puts "->\tMethod #{obj.path} (visibility: #{obj.visibility})"
      # Attach better source code
      obj.attach_source(statement, parser.file)
      parse_block
    end
  end
end