class Array
  def place(a) Insertion.new(self, a) end
end

class Insertion
  def initialize(list, value) @list, @value = list, value end
  def before(val) insertion(val, 0) end
  def after(val, ignore_subsections = true) insertion(val, 1, ignore_subsections) end
  private
  def insertion(val, rel, ignore_subsections = true) 
    if index = @list.index(val)
      if ignore_subsections && rel == 1 && @list[index + 1].is_a?(Array)
        rel += 1
      end
      @list[index+rel,0] = @value 
    end
    @list
  end
end
