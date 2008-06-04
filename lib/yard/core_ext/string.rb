class String
  # @it should turn hello_world into HelloWorld
  #   "hello_world".camelcase.should == "HelloWorld"
  def underscore
    gsub(/([a-z])([A-Z])/, '\1_\2').downcase 
  end
  
  # @it should turn HelloWorld into hello_world
  #   "HelloWorld".underscore.should == "hello_world"
  def camelcase
    gsub(/([a-z])_([a-z])/i) { $1 + $2.upcase }.sub(/^(.)/) { $1.upcase } 
  end
end
