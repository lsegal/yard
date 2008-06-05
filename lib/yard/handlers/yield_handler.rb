class YARD::Handlers::YieldHandler < YARD::Handlers::Base
  handles TkYIELD
  
  def process
    return unless owner.is_a?(MethodObject) # Only methods yield
    return if owner.has_tag? :yield         # Don't override yield tags
    return if owner.has_tag? :yieldparam    # Same thing.

    yieldtag = Tags::Tag.new(:yield, "", [])
    owner.tags << yieldtag
    tokval_list(statement.tokens[2..-1], Token).each do |item|
      item = item.inspect unless item.is_a?(String)
      if item == "self"
        yieldtag.types << '_self'
        owner.tags << Tags::Tag.new(:yieldparam, 
          "the object that the method was called on", owner.namespace.path, '_self')
      elsif item == "super"
        yieldtag.types << '_super'
        owner.tags << Tags::Tag.new(:yieldparam, 
          "the result of the method from the superclass", nil, '_super')
      else
        yieldtag.types << item
      end
    end
  end
end