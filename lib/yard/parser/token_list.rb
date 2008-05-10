class TokenList < Array
  def to_s
    collect {|t| t.text }.join
  end
end