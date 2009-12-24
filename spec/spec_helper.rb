require "rubygems"
require "spec"

require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'yard'))

def parse_file(file, thisfile = __FILE__, log_level = log.level, ext = '.rb.txt')
  Registry.clear
  path = File.join(File.dirname(thisfile), 'examples', file.to_s + ext)
  YARD::Parser::SourceParser.parse(path, [], log_level)
end

def described_in_docs(klass, meth, file = nil)
  YARD::Tags::Library.define_tag "RSpec Specification", :it, :with_raw_title_and_text

  # Parse the file (could be multiple files)
  if file
    filename = File.join(YARD::ROOT, file)
    YARD::Parser::SourceParser.new.parse(filename)
  else
    $".find_all {|p| p.include? klass.class_name.underscore }.each do |filename|
      next unless File.exists? filename
      YARD::Parser::SourceParser.new.parse(filename)
    end
  end
  
  # Get the object
  objname = klass.name + (meth[0,1] == '#' ? meth : '::' + meth)
  obj = Registry.at(objname)
  raise "Cannot find object #{objname} described by spec." unless obj
  raise "#{obj.path} has no @it tags to spec." unless obj.has_tag? :it
  
  # Run examples
  describe(klass, meth) do
    obj.tags(:it).each do |it|
      path = File.relative_path(YARD::ROOT, obj.file)
      it(it.name + " (from #{path}:#{obj.line})") do 
        begin
          eval(it.text)
        rescue => e
          e.set_backtrace(["#{path}:#{obj.line}:in @it tag specification"])
          raise e
        end
      end
    end
  end
end

def docspec(objname = self.class.description, klass = self.class.described_type)
  # Parse the file (could be multiple files)
  $".find_all {|p| p.include? klass.class_name.underscore }.each do |filename|
    filename = File.join(YARD::ROOT, filename)
    next unless File.exists? filename
    YARD::Parser::SourceParser.new.parse(filename)
  end
  
  # Get the object
  objname = klass.name + objname if objname =~ /^[^A-Z]/
  obj = Registry.at(objname)
  raise "Cannot find object #{objname} described by spec." unless obj
  raise "#{obj.path} has no @example tags to spec." unless obj.has_tag? :example
  
  # Run examples
  obj.tags(:example).each do |exs|
    exs.text.split(/\n/).each do |ex|
      begin
        hash = eval("{ #{ex} }")
        hash.keys.first.should == hash.values.first
      rescue => e
        raise e, "#{e.message}\nInvalid spec example in #{objname}:\n\n\t#{ex}\n"
      end
    end
  end
end

include YARD