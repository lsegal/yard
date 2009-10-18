def init
  sections :header, [:method_signature, T('../docstring')]
end

def format_object_title(object)
  title = "Method: #{object.name(true)}"
  title += " (#{object.namespace})" if object.namespace != Registry.root
  title
end

def signature(meth)
  type = (meth.tag(:return) && meth.tag(:return).types ? meth.tag(:return).types.first : nil) || "Object"
  scope = meth.scope == :class ? "#{meth.namespace.name}." : "#{meth.namespace.name.to_s.downcase}."
  name = meth.name
  blk = format_block(meth)
  args = format_args(meth)
  extras = []
  extras_text = ''
  if rw = meth.namespace.attributes[meth.scope][meth.name]
    attname = [rw[:read] ? 'read' : nil, rw[:write] ? 'write' : nil].compact
    attname = attname.size == 1 ? attname.join('') + 'only' : nil
    extras << attname if attname
  end
  extras << meth.visibility if meth.visibility != :public
  extras_text = '(' + extras.join(", ") + ')' unless extras.empty?
  title = "%s%s%s %s -> %s %s" % [scope, name, args, blk, type, extras_text]
  title.gsub(/\s+/, ' ')
end
