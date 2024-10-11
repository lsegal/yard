# frozen_string_literal: true
module YARD::CodeObjects
  register_separator NSEP, :constant

  # A +ConstantObject+ represents a Ruby constant (not a module or class).
  # To access the constant's (source code) value, use {#value}.
  class ConstantObject < Base
    # The source code representing the constant's value
    # @return [String] the value the constant is set to
    attr_reader :value

    def value=(value)
      @value = format_source(value)
    end

    # @return [Base, nil] the target object the constant points to
    def target
      return @target if instance_variable_defined?(:@target)

      if !value.empty? &&
        (target = P(namespace, value)) &&
        !target.is_a?(YARD::CodeObjects::Proxy) &&
        target != self
        @target = target
      else
        @target = nil
      end
      @target
    rescue YARD::Parser::UndocumentableError
      # means the value isn't an alias to another object
      @target = nil
    end
  end
end
