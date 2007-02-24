require File.dirname(__FILE__) + '/code_object_handler'
Dir[File.dirname(__FILE__) + '/*_handler.rb'].reject {|f| f =~ /code_object_handler\.rb$/ }.each {|file| require file }
