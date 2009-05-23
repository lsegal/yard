module YARD::CodeObjects
  class ExtendedMethodObject
    instance_methods.each {|m| undef_method(m) unless m =~ /^__/ || m.to_sym == :object_id }
    
    def scope; :class end
    def initialize(obj) @del = obj end
    def method_missing(sym, *args, &block) @del.__send__(sym, *args, &block) end
  end
end