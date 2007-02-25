class YARD::MixinHandler < YARD::CodeObjectHandler
  handles /\Ainclude\b/
  
  def process
    return unless object.is_a? YARD::CodeObjectWithMethods
    object.mixins.push eval(statement.tokens[1..-1].to_s).to_s
    object.mixins.uniq!
  end
end