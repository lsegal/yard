require 'yard'
include YARD

Namespace.load("Yardoc", true)
ac = File.open("doc/all-classes.html", "w") 
ac.puts <<-eof
<html>
  <head>
    <base target="main" />
  </head>
  <body>
eof
Namespace.all.sort.each do |path|
  object = Namespace.at(path)
  next unless object.is_a? ClassObject
  ac.puts "<a href='" + path.gsub("::","_") + ".html'>" + path + "</a><br />"
  File.open("doc/#{path.gsub('::','_')}.html", "w") {|f| f.write(object.format) }
end
ac.puts "</body></html>"
ac.close
