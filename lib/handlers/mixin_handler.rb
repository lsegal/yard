class YARD::MixinHandler < YARD::CodeObjectHandler
  handles /\Ainclude\b/
  
  def process
    return unless object.is_a? YARD::CodeObjectWithMethods
    begin
      # Verify that it's a real list with no funny stuff
      object.mixins.push *eval("[ " + statement.tokens[1..-1].to_s + " ]").to_s.split(",")
    rescue NameError
      object.mixins.push *statement.tokens[1..-1].to_s.split(",")
    rescue SyntaxError
      Logger.warning "Undocumentable included module #{statement.tokens[1..-1].to_s}"
    end
    object.mixins.map! {|mixin| mixin.strip }
    object.mixins.flatten!
    object.mixins.uniq!
  end
end