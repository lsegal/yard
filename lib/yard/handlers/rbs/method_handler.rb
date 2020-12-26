# frozen_string_literal: true

# Handles classes
class YARD::Handlers::RBS::MethodHandler < YARD::Handlers::RBS::Base
  handles ::RBS::AST::Members::MethodDefinition

  process do
    name = statement.name.to_s
    scope = statement.kind == :instance ? :instance : :class
    obj = register MethodObject.new(namespace, name, scope)
    return unless obj.docstring.tags.empty?

    if statement.types.size == 1
      sig = statement.types.first
      obj.parameters = build_params(sig.type)
      obj.signature = build_signature(obj.parameters)
      process_sig(sig, obj)
    else
      statement.types.each do |sig|
        sig_info = build_signature(build_params(sig.type))
        tag = YARD::Tags::OverloadTag.new(:overload, sig_info)
        obj.docstring.add_tag(tag)
        process_sig(sig, tag)
        tag.object = obj
      end
    end
  end

  def process_sig(sig, obj)
    ds = obj.docstring
    tag_klass = YARD::Tags::Tag

    (sig.type.required_positionals + sig.type.optional_positionals).each do |param|
      ds.add_tag(tag_klass.new(:param, '', convert_type(param.type), param.name.to_s))
    end

    if sig.type.optional_keywords
      sig.type.optional_keywords.each do |kw, type|
        ds.add_tag(tag_klass.new(:param, '', convert_type(type), kw.to_s))
      end
    end

    if sig.type.required_keywords
      sig.type.required_keywords.each do |kw, type|
        ds.add_tag(tag_klass.new(:param, '', convert_type(type), kw.to_s))
      end
    end

    if sig.block
      (sig.block.type.required_positionals + sig.block.type.optional_positionals).each do |param|
        ds.add_tag(tag_klass.new(:yieldparam, '', convert_type(param.type), param.name.to_s))
      end
      if sig.block.type.return_type
        ds.add_tag(tag_klass.new(:yieldreturn, '', convert_type(sig.block.type.return_type)))
      end
    end

    if sig.type.return_type
      ds.add_tag(tag_klass.new(:return, '', convert_type(sig.type.return_type)))
    end
  end

  def build_signature(params)
    prefix = statement.kind == :instance ? '' : 'self.'
    params_part = params_to_sig(params)
    params_part = "(#{params_part})" unless params_part.empty?
    "def #{prefix}#{statement.name}#{params_part}"
  end

  def build_params(type)
    params = []
    params += type.required_positionals.map {|t| [t.name.to_s, nil] }
    params += type.optional_positionals.map {|t| [t.name.to_s, '?'] }
    params += type.required_keywords.map {|kw, t| ["#{kw}:", nil] }
    params += type.optional_keywords.map {|kw, t| ["#{kw}:", '?'] }
    params.push(['*args', nil]) if type.rest_positionals
    params.push(['**kwargs', nil]) if type.rest_keywords
    params
  end

  def params_to_sig(params)
    params.map {|param| param.compact.join(param =~ /:$/ ? ' ' : ' = ') }.join(', ')
  end

  def convert_type(typename)
    typename = typename.to_s
    result = case typename
    when 'bool', 'boolish'
      'Boolean'
    when 'untyped'
      'Object'
    else
      typename
    end

    [result]
  end
end
