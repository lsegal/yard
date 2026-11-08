# frozen_string_literal: true
# Handles RBS attr_reader, attr_writer, and attr_accessor declarations.
#
# Registers one or two {YARD::CodeObjects::MethodObject} instances (reader
# and/or writer) with @return / @param tags derived from the RBS type.
class YARD::Handlers::RBS::AttributeHandler < YARD::Handlers::RBS::Base
  handles :attr_reader, :attr_writer, :attr_accessor

  process do
    attr_name  = statement.name
    rbs_type   = statement.attr_rbs_type
    yard_types = rbs_type ? YARD::Handlers::RBS::MethodHandler.rbs_type_to_yard_types(rbs_type) : nil
    mscope     = statement.scope == :class ? :class : :instance

    case statement.type
    when :attr_reader
      register_reader(attr_name, yard_types, mscope)
      register_existing_attribute_method(attr_name, "#{attr_name}=", :write, mscope)
    when :attr_writer
      register_existing_attribute_method(attr_name, attr_name, :read, mscope)
      register_writer(attr_name, yard_types, mscope)
    when :attr_accessor
      register_reader(attr_name, yard_types, mscope)
      register_writer(attr_name, yard_types, mscope)
    end
  end

  private

  def register_reader(name, types, scope)
    obj = MethodObject.new(namespace, name, scope)
    obj.source ||= "def #{name}\n  @#{name}\nend"
    obj.signature ||= "def #{name}"
    obj = register(obj)
    obj.visibility = statement.visibility if statement.visibility
    obj.docstring = "Returns the value of attribute #{name}." if obj.docstring.blank?(false)
    apply_tag_types(obj, :return, types)
    namespace.attributes[obj.scope][name] ||= SymbolHash[:read => nil, :write => nil]
    namespace.attributes[obj.scope][name][:read] = obj
    obj
  end

  def register_writer(name, types, scope)
    obj = MethodObject.new(namespace, "#{name}=", scope)
    obj.parameters = [['value', nil]]
    obj.source ||= "def #{name}=(value)\n  @#{name} = value\nend"
    obj.signature ||= "def #{name}=(value)"
    obj = register(obj)
    obj.visibility = statement.visibility if statement.visibility
    obj.docstring = "Sets the attribute #{name}\n@param value the value to set the attribute #{name} to." if obj.docstring.blank?(false)
    apply_tag_types(obj, :param, types, "value")
    namespace.attributes[obj.scope][name] ||= SymbolHash[:read => nil, :write => nil]
    namespace.attributes[obj.scope][name][:write] = obj
    obj
  end

  def register_existing_attribute_method(attr_name, meth_name, type, scope)
    namespace.attributes[scope][attr_name] ||= SymbolHash[:read => nil, :write => nil]
    return if namespace.attributes[scope][attr_name][type]

    obj = namespace.children.find do |other|
      other.name == meth_name.to_sym && other.scope == scope
    end

    namespace.attributes[scope][attr_name][type] = obj if obj
  end

  def apply_tag_types(obj, tag_name, types, tag_param_name = nil)
    return unless types

    tag = obj.tags(tag_name).find do |existing_tag|
      existing_tag.name == tag_param_name
    end

    if tag
      tag.types ||= types
    else
      obj.add_tag YARD::Tags::Tag.new(tag_name, '', types, tag_param_name)
    end
  end
end
