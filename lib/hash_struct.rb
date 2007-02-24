class HashStruct < Hash
  def initialize(hash = {})
    hash.each {|key, value| send('[]=', key, value) } 
  end
  
  def method_missing(sym, *args, &block)
    regmatch = /=$/
    if sym.to_s =~ regmatch
      send('[]=', sym.to_s.gsub(regmatch, ''), *args)
    else
      send('[]', sym)
    end
  end

  def [](key)
    super(key.to_sym)
  end
  
  def []=(key, val)
    super(key.to_sym, val)
  end
end