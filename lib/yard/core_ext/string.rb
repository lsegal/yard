class String
  # Separates capital letters following lower case letters by an underscore
  # and returns the entire string in lower case
  # 
  # @example
  #   "FooBar".underscore # => "foo_bar"
  # @return [String] the underscored lower case string
  def underscore
    gsub(/([a-z])([A-Z])/, '\1_\2').downcase.gsub('::', '/')
  end
  
  # Camel cases any underscored text.
  # 
  # @example
  #   "foo_bar_baz".camelcase # => "FooBarBaz"
  # @return [String] the camel cased text
  def camelcase
    gsub(/([a-z])_([a-z])/i) { $1 + $2.upcase }.sub(/^(.)/) { $1.upcase }.gsub('/', '::') 
  end
end
