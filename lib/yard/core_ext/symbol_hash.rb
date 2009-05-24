class SymbolHash < Hash
  def initialize(symbolize_value = true)
    @symbolize_value = symbolize_value
  end
  
  def self.[](*hsh)
    obj = new;
    if hsh.size == 1 && hsh.first.is_a?(Hash)
      hsh.first.each {|k,v| obj[k] = v }
    else
      0.step(hsh.size, 2) {|n| obj[hsh[n]] = hsh[n+1] }
    end
    obj
  end
  
  def []=(key, value) 
    super(key.to_sym, value.instance_of?(String) && @symbolize_value ? value.to_sym : value) 
  end
  def [](key) super(key.to_sym) end
  def delete(key) super(key.to_sym) end
  def has_key?(key) super(key.to_sym) end
  def update(hsh) hsh.each {|k,v| self[k] = v }; self end
  alias_method :merge!, :update
  def merge(hsh) dup.merge!(hsh) end
end
