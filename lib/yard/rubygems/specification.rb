require 'rubygems/specification'

class Gem::Specification
  # @since 0.5.3
  def has_yardoc=(value)
    @has_rdoc = value ? 'yard' : false
  end

  def has_yardoc
    @has_rdoc == 'yard'
  end

#  undef has_rdoc? if method_defined?(:has_rdoc?)
  def has_rdoc?
    (@has_rdoc ||= true) && @has_rdoc != 'yard'
  end

  alias has_yardoc? has_yardoc

  # has_rdoc should not be ignored!
  if respond_to?(:overwrite_accessor)
    overwrite_accessor(:has_rdoc) { @has_rdoc ||= true }
    overwrite_accessor(:has_rdoc=) {|v| @has_rdoc = v }
  else
    undef has_rdoc=
    attr_accessor :has_rdoc
  end

  if defined?(Gem::VERSION) && Gem::VERSION >= '1.7.'
    def _dump_with_rdoc(limit)
      dmp = _dump_without_rdoc(limit)
      dmp[15] = @has_rdoc if dmp[15] == true
      dmp
    end
    alias _dump_without_rdoc _dump
    alias _dump _dump_with_rdoc

    @@default_value[:has_rdoc] = true if defined?(@@default_value)
    @@attributes << 'has_rdoc' if defined?(@@attributes)
    @@nil_attributes << 'has_rdoc' if defined?(@@nil_attributes)
  end
end
