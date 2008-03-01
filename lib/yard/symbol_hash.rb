class SymbolHash < Hash
  def []=(key, value) super(key.to_sym, value) end
  def [](key) super(key.to_sym) end
end