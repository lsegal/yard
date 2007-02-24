#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/lib/quick_doc'
doc = YARD::QuickDoc.new(ARGV[0])

#puts YARD::Namespace.all.reject {|k| k == '' }.select {|x| x =~ /Handler/ }

#require File.dirname(__FILE__) + '/lib/source_parser'
#YARD::SourceParser.parse('lib/hash_struct.rb')