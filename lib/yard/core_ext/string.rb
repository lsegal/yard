class String
  def underscore
    gsub(/([a-z])([A-Z])/, '\1_\2').downcase 
  end
  
  def camelcase
    gsub(/([a-z])_([a-z])/i) { $1 + $2.upcase }.sub(/^(.)/) { $1.upcase } 
  end
end
