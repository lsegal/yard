class YARD::MixinHandler < YARD::CodeObjectHandler
  handles /\Ainclude\b/
  
  def process
    return unless object.is_a? YARD::CodeObjectWithMethods
    begin
      object.mixins.push eval("[ " + statement.tokens[1..-1].to_s + " ]").to_s
    rescue NameError
      object.mixins.push statement.tokens[1..-1].to_s
    end
    object.mixins.flatten!
    object.mixins.uniq!
  end
end