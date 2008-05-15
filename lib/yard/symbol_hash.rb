class SymbolHash < Hash
  def []=(key, value) super(key.to_sym, value.instance_of?(String) ? value.to_sym : value) end
  def [](key) super(key.to_sym) end
  def delete(key) super(key.to_sym) end
  def has_key?(key) super(key.to_sym) end
  def update(hsh) hsh.each {|k,v| self[k] = v } end
  alias_method :merge, :update
end