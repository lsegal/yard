require 'rubygems/specification'

class Gem::Specification
  # has_rdoc should not be ignored!
  overwrite_accessor(:has_rdoc) { @has_rdoc }
  overwrite_accessor(:has_rdoc=) {|v| @has_rdoc = v }

  # @since 0.5.3
  def has_yardoc=(value)
    @has_rdoc = 'yard'
  end

  def has_yardoc
    @has_rdoc == 'yard'
  end

  undef has_rdoc?
  def has_rdoc?
    @has_rdoc && @has_rdoc != 'yard'
  end

  alias has_yardoc? has_yardoc
end
