class YARD::Handlers::ExceptionHandler < YARD::Handlers::Base
  handles /\Araise(\s|\()/
  
  def process
    return unless owner.is_a?(MethodObject) # Only methods yield
    return if owner.has_tag? :raise

    klass = statement.tokens[2..-1].reject {|t| TkWhitespace === t || TkLPAREN === t }.first
    if klass && TkCONSTANT === klass
      owner.tags << Tags::Tag.new(:raise, '', klass.text)
    end
  end
end