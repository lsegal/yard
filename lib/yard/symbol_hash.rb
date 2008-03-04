class SymbolHash < Hash
  def []=(key, value) super(key.to_sym, value.is_a?(String) ? value.to_sym : value) end
  def [](key) super(key.to_sym) end
  def delete(key) super(key.to_sym) end
end