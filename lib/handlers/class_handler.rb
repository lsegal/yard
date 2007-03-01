class YARD::ClassHandler < YARD::CodeObjectHandler
  handles RubyToken::TkCLASS
  
  def process
    words = statement.tokens.to_s.strip.split(/\s+/)
    class_name, superclass = words[1], (words[3] || "Object")
    if class_name == "<<"
      if words[2] == "self"
        class_name = nil
      else
        class_name = "Anonymous$#{class_name}"
      end
    end
    
    if class_name.nil?
      # This is a class << self block. We change the scope to class level methods
      # and reset the visibility to public, but we don't enter a new namespace.
      scope, vis = current_namespace.attributes[:scope], current_visibility
      current_visibility = :public
      current_namespace.attributes[:scope] = :class
      parse_block
      current_namespace.attributes[:scope], current_visibility = scope, vis
    else
      class_name = move_to_namespace(class_name)
      class_obj = YARD::ClassObject.new(class_name, superclass, object, statement.comments)
      enter_namespace(class_obj) { parse_block }
    end
  end
end