def parse_file(file, thisfile = __FILE__)
  path = File.join(File.dirname(thisfile), 'examples', file.to_s + '.rb.txt')
  YARD::Parser::SourceParser.parse(path)
end

include Handlers