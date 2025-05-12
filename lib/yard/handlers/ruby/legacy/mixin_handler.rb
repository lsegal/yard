# frozen_string_literal: true
# (see Ruby::MixinHandler)
class YARD::Handlers::Ruby::Legacy::MixinHandler < YARD::Handlers::Ruby::Legacy::Base
  handles(/\Ainclude(\s|\()/)
  namespace_only

  process do
    errors = []
    statement.tokens[1..-1].to_s.split(/\s*,\s*/).reverse_each do |mixin|
      mixin = mixin.strip
      begin
        process_mixin(mixin)
      rescue YARD::Parser::UndocumentableError => e
        errors << e.message
      end
    end

    unless errors.empty?
      msg = errors.size == 1 ? ": #{errors[0]}" : "s: #{errors.join(", ")}"
      raise YARD::Parser::UndocumentableError, "mixin#{msg} for class #{namespace.path}"
    end
  end

  private

  def process_mixin(mixin)
    mixmatch = mixin[/\A(#{NAMESPACEMATCH})/o, 1]
    raise YARD::Parser::UndocumentableError unless mixmatch

    obj = case obj = Proxy.new(namespace, mixmatch)
          when ConstantObject # If a constant is included, use its value as the real object
            Proxy.new(namespace, obj.value, :module)
          else
            Proxy.new(namespace, mixmatch, :module)
          end

    namespace.mixins(scope).unshift(obj) unless namespace.mixins(scope).include?(obj)
  end
end
