module YARD::CodeObjects
  class Proxy < Base
    # Dispatches the method to the resolved object
    # 
    # @raise NoMethodError if the proxy cannot find the real object
    def method_missing(meth, *args, &block)
      if obj = path.to_obj
        obj.send(meth, *args, &block)
      else
        super
      end
    end
  end
end