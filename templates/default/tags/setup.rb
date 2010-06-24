def init
  tags = Tags::Library.visible_tags - [:abstract, :deprecated, :note, :todo]
  create_tag_methods(tags - [:example, :option, :overload, :see])
  sections :index, tags
  sections.any(:overload).push(T('docstring'))
end

def return
  if object.type == :method
    return if object.name == :initialize && object.scope == :instance
    return if object.tags(:return).size == 1 && object.tag(:return).types == ['void']
  end
  tag :return, :no_names => true
end

private

def tag(name, opts = {})
  return unless object.has_tag?(name)
  @no_names = true if opts[:no_names]
  @no_types = true if opts[:no_types]
  @name = name
  out = erb('tag')
  @no_names, @no_types = nil, nil
  out
end

def create_tag_methods(tags)
  tags.each do |tag|
    next if respond_to?(tag)
    instance_eval(<<-eof, __FILE__, __LINE__ + 1)
      def #{tag}
        opts = {:no_types => true, :no_names => true}
        case Tags::Library.factory_method_for(#{tag.inspect})
        when :with_types
          opts[:no_types] = false
        when :with_types_and_name
          opts[:no_types] = false
          opts[:no_names] = false
        when :with_name
          opts[:no_names] = false
        end
        tag #{tag.inspect}, opts
      end
    eof
  end
end
