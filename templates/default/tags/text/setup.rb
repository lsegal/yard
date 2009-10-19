def format_source(value)
  sp = value.split("\n").last[/^(\s+)/, 1]
  num = sp ? sp.size : 0
  value.gsub(/^\s{#{num}}/, '')
end