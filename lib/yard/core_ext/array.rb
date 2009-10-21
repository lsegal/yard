class Array
  # Places a value before or after another object (by value) in
  # an array. This is used in tandem with the before and after
  # methods of the {Insertion} class.
  # 
  # @example Places an item before another
  #   [1, 2, 3].place(4).before(3) # => [1, 2, 4, 3]
  # @example Places an item after another
  #   [:a, :b, :c].place(:x).after(:a) # => [:a, :x, :b, :c]
  # @param [Object] value value to insert
  # @return [Insertion] an insertion object to 
  # @see Insertion#before
  # @see Insertion#after
  def place(value) Insertion.new(self, value) end
end

# The Insertion class inserts a value before or after another
# value in a list.
# 
# @example
#   Insertion.new([1, 2, 3], 4).before(3) # => [1, 2, 4, 3]
class Insertion
  # Creates an insertion object on a list with a value to be
  # inserted. To finalize the insertion, call {#before} or
  # {#after} on the object.
  # 
  # @param [Array] list the list to perform the insertion on
  # @param [Object] value the value to insert
  def initialize(list, value) @list, @value = list, value end
    
  # Inserts the value before +val+
  # @param [Object] val the object the value will be inserted before
  def before(val) insertion(val, 0) end
    
  # Inserts the value after +val+. 
  # 
  # @example If subsections are ignored
  #   Insertion.new([1, [2], 3], :X).after(1) # => [1, [2], :X, 3]
  # @param [Object] val the object the value will be inserted after
  # @param [Boolean] ignore_subsections treat any Array objects that follow val as
  #   associated and do not split them up.
  def after(val, ignore_subsections = true) insertion(val, 1, ignore_subsections) end

  private

  # This method performs the actual insertion
  # 
  # @param [Object] val the value to insert
  # @param [Fixnum] rel the relative index (0 or 1) of where the object
  #   should be placed
  # @param [Boolean] ignore_subsections see {#after} for an explanation.
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
