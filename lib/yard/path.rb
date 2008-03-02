class YARD::Path
  attr_reader :namespace, :name

  # @see YARD::Path#initialize
  def self.new(object)
    @instances ||= {}
    rpath = "#{object.parent ? object.parent.path : ''}+#{object.name}".to_sym
    if obj = @instances[rpath]
      obj
    else
      @instances[rpath] = super
    end
  end
  
  # @param [CodeObjects::Base] object: the code object to represent a path for
  def initialize(object)
    @namespace, @name = namespace, name.to_sym
  end
  
  def to_obj
    obj = namespace
    while obj
      found = Registry.at(obj + @path)
      break found if found
      obj = obj.parent
      p obj
    end
  end
  
  def +(other)
    case other
    when String
      "#{path}::#{other}"
    when Base
      "#{path}::#{other.path}"
    end
  end
end

# @see YARD::Path#initialize
#def P(namespace, name) 
#  
#end