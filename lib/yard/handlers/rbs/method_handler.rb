# frozen_string_literal: true
# Handles RBS method definitions (def name: signature).
#
# Creates a {YARD::CodeObjects::MethodObject} for each declaration
# and infers @param, @return, @yield, and @yieldparam tags from the
# RBS type signature when those tags are absent from the docstring.
class YARD::Handlers::RBS::MethodHandler < YARD::Handlers::RBS::Base
  handles :method_def

  process do
    meth_scope = statement.visibility == :class ? :class : :instance
    obj = register MethodObject.new(namespace, statement.name, meth_scope)
    apply_signature_tags(obj, statement.signatures)

    # For initialize, ensure the return type is the class, not void.
    if statement.name == 'initialize'
      ret_tags = obj.tags(:return)
      if ret_tags.none? || (ret_tags.length == 1 && ret_tags.first.types == ['void'])
        obj.docstring.delete_tags(:return)
        obj.add_tag YARD::Tags::Tag.new(:return, "a new instance of #{namespace.name}",
                                        [namespace.name.to_s])
      end
    end
  end

  # Convert an RBS type string to an array of YARD type strings.
  #
  # @param rbs [String] e.g. "String | Integer", "Array[String]", "bool"
  # @return [Array<String>]
  def self.rbs_type_to_yard_types(rbs)
    rbs = rbs.strip
    return ['void']    if rbs == 'void'
    return ['Boolean'] if rbs == 'bool'
    return ['Object']  if rbs == 'untyped'
    return ['nil']     if rbs == 'nil'

    # Strip outer parentheses: `(String | Integer)` → recurse on inner.
    if rbs.start_with?('(') && rbs.end_with?(')') && bracket_depth(rbs[1..-2]) == 0
      return rbs_type_to_yard_types(rbs[1..-2])
    end

    # `Type?` is shorthand for `Type | nil` when the ? is outermost.
    if rbs =~ /\A(.+)\?\z/ && bracket_depth($1) == 0
      return rbs_type_to_yard_types($1) + ['nil']
    end

    split_on_pipe(rbs).map { |t| t.strip }
  end

  private

  # Apply tags from all overload signatures to the method object.
  def apply_signature_tags(obj, sigs)
    return if sigs.nil? || sigs.empty?

    if sigs.length == 1
      # Single signature: add @param and @return directly.
      add_param_return_tags(obj, sigs.first)
    else
      # Multiple signatures: add @overload tags.
      sigs.each { |sig| add_overload_tag(obj, statement.name, sig) }
    end
  end

  # Add @param / @return / @yield / @yieldparam from a single overload sig.
  def add_param_return_tags(obj, sig)
    parsed = parse_function_type(sig)

    parsed[:params].each do |p|
      next if p[:block]  # block param handled via @yield below
      tag_name = p[:name] ? p[:name].to_s : nil
      next if tag_name && obj.tags(:param).any? { |t| t.name == tag_name }
      obj.add_tag YARD::Tags::Tag.new(:param, '', p[:types], tag_name)
    end

    if (blk = parsed[:block_param])
      add_yield_tags(obj, blk)
    end

    unless obj.has_tag?(:return)
      obj.add_tag YARD::Tags::Tag.new(:return, '', parsed[:return_types])
    end
  end

  # Add an @overload tag for one signature overload.
  def add_overload_tag(obj, meth_name, sig)
    parsed     = parse_function_type(sig)
    param_sigs = parsed[:params].reject { |p| p[:block] }.map.with_index do |p, idx|
      p[:name] || "arg#{idx}"
    end

    # Build the overload tag text:  signature line + nested @param/@return lines.
    lines = ["#{meth_name}(#{param_sigs.join(', ')})"]
    parsed[:params].reject { |p| p[:block] }.each_with_index do |p, idx|
      pname = p[:name] || "arg#{idx}"
      lines << "  @param #{pname} [#{p[:types].join(', ')}]"
    end

    if (blk = parsed[:block_param])
      add_yield_tags(obj, blk)
    end

    lines << "  @return [#{parsed[:return_types].join(', ')}]"
    obj.add_tag YARD::Tags::OverloadTag.new(:overload, lines.join("\n"))
  end

  # Add @yield and @yieldparam tags from a parsed block type.
  def add_yield_tags(obj, blk)
    return if obj.has_tag?(:yield) && obj.has_tag?(:yieldparam)
    obj.add_tag YARD::Tags::Tag.new(:yield, '') unless obj.has_tag?(:yield)
    blk[:params].each_with_index do |p, idx|
      pname = p[:name] || "arg#{idx}"
      next if obj.tags(:yieldparam).any? { |t| t.name == pname }
      obj.add_tag YARD::Tags::Tag.new(:yieldparam, '', p[:types], pname)
    end
    unless obj.has_tag?(:yieldreturn)
      obj.add_tag YARD::Tags::Tag.new(:yieldreturn, '', self.class.rbs_type_to_yard_types(blk[:return_type] || 'void'))
    end
  end

  # Parse a single RBS function type string (one overload) into its components.
  #
  # @param sig [String] e.g. "(String name, Integer age) -> String"
  # @return [Hash] { :params => [...], :block_param => Hash|nil, :return_types => [...] }
  def parse_function_type(sig)
    sig = sig.strip
    return { :params => [], :block_param => nil, :return_types => ['void'] } if sig.empty?

    remaining = sig
    params = []
    block_param = nil

    # Skip method type parameters: leading `[...]`.
    if remaining.start_with?('[')
      close = find_matching(remaining, 0, '[', ']')
      raise YARD::Parser::UndocumentableError, "malformed signature (unclosed '['): #{sig}" if close.nil?
      remaining = remaining[close + 1..-1].lstrip
    end

    # 1. Extract positional/keyword params: leading `(...)`.
    if remaining.start_with?('(')
      close = find_matching(remaining, 0, '(', ')')
      raise YARD::Parser::UndocumentableError, "malformed signature (unclosed '('): #{sig}" if close.nil?
      params_str = remaining[1...close]
      remaining  = remaining[close + 1..-1].lstrip
      params  = parse_params_list(params_str)
    end

    # 2. Extract block type: `{ ... }`, or an optional block `?{ ... }`.
    remaining = remaining.sub(/\A\?\s*(?=\{)/, '')
    if remaining.start_with?('{')
      close = find_matching(remaining, 0, '{', '}')
      raise YARD::Parser::UndocumentableError, "malformed signature (unclosed '{'): #{sig}" if close.nil?
      block_inner  = remaining[1...close]
      remaining    = remaining[close + 1..-1].lstrip
      block_param  = parse_block_type(block_inner)
    end

    # 3. Return type after `->`.
    return_types = if remaining =~ /\A->\s*(.*)\z/
                     self.class.rbs_type_to_yard_types($1.strip)
                   else
                     ['void']
                   end

    { :params => params, :block_param => block_param, :return_types => return_types }
  end

  # Parse a comma-separated parameter list (content inside outer parens).
  def parse_params_list(str)
    str = str.strip
    return [] if str.empty?

    split_by_comma(str).map { |p| parse_single_param(p.strip) }.compact
  end

  # Parse one parameter from an RBS param list.
  def parse_single_param(param)
    return nil if param.empty?

    optional = false
    rest     = false

    # Optional marker `?`.
    if param.start_with?('?') && !param.start_with?('?(')
      optional = true
      param    = param[1..-1].lstrip
    end

    # Double-splat `**` (rest keyword).
    if param.start_with?('**')
      rest  = true
      param = param[2..-1].lstrip
    # Single-splat `*` (rest positional).
    elsif param.start_with?('*') && !param.start_with?('*)')
      rest  = true
      param = param[1..-1].lstrip
    end

    # Block-type proc: `^(...)`.
    if param.start_with?('^')
      return { :name => nil, :types => [param], :optional => false, :rest => false, :block => true }
    end

    # Keyword parameter: `name: Type` or `?name: Type`.
    if param =~ /\A([a-z_]\w*)\s*:\s*(.*)\z/ && !rest
      kw_name = $1
      kw_type = $2.strip
      return { :name => "#{kw_name}:", :types => self.class.rbs_type_to_yard_types(kw_type),
               :optional => optional, :rest => false }
    end

    # Positional: `Type [param_name]`.
    type_str, param_name = extract_type_and_name(param)
    { :name => param_name, :types => self.class.rbs_type_to_yard_types(type_str),
      :optional => optional, :rest => rest }
  end

  # Split a type+name string like "Array[String] names" into ["Array[String]", "names"].
  # The name is the trailing lowercase identifier (if any).
  def extract_type_and_name(str)
    str = str.strip
    if str =~ /\A(.*\S)\s+([a-z_]\w*)\z/m
      type_part = $1.strip
      name_part = $2
      # Exclude RBS type keywords from being mistaken for names.
      unless %w[void untyped nil bool top bottom self instance class].include?(name_part)
        return [type_part, name_part] unless type_part.empty?
      end
    end
    [str, nil]
  end

  # Parse the inside of a `{ ... }` block type, e.g. "(Integer) -> String".
  def parse_block_type(inner)
    inner = inner.strip
    params = []
    ret    = nil

    if inner.start_with?('(')
      close  = find_matching(inner, 0, '(', ')')
      raise YARD::Parser::UndocumentableError, "malformed block type (unclosed '('): #{inner}" if close.nil?
      params = parse_params_list(inner[1...close])
      rest   = inner[close + 1..-1].lstrip
    else
      rest = inner
    end

    ret = $1.strip if rest =~ /\A->\s*(.*)\z/
    { :params => params, :return_type => ret }
  end

  # Find the index of the matching close bracket starting from +start+.
  # @return [nil] if no matching bracket is found (malformed input).
  def find_matching(str, start, open, close)
    depth = 0
    (start...str.length).each do |i|
      case str[i]
      when open  then depth += 1
      when close
        depth -= 1
        return i if depth == 0
      end
    end
    nil
  end

  # Split +str+ on commas that are not inside brackets.
  def split_by_comma(str)
    depth = 0
    parts = []
    cur   = String.new('')
    str.each_char do |c|
      case c
      when '(', '[', '{'
        depth += 1
        cur << c
      when ')', ']', '}'
        depth -= 1
        cur << c
      when ','
        if depth == 0
          parts << cur.strip
          cur = String.new('')
        else
          cur << c
        end
      else
        cur << c
      end
    end
    parts << cur.strip unless cur.strip.empty?
    parts
  end

  # Split +str+ on `|` that are not inside brackets.
  def self.split_on_pipe(str)
    depth = 0
    parts = []
    cur   = String.new('')
    str.each_char do |c|
      case c
      when '(', '[', '{'
        depth += 1
        cur << c
      when ')', ']', '}'
        depth -= 1
        cur << c
      when '|'
        if depth == 0
          parts << cur.strip
          cur = String.new('')
        else
          cur << c
        end
      else
        cur << c
      end
    end
    parts << cur.strip unless cur.strip.empty?
    parts
  end

  # Return the bracket depth of the full string (should be 0 for well-formed types).
  def self.bracket_depth(str)
    depth = 0
    str.each_char do |c|
      case c
      when '(', '[', '{' then depth += 1
      when ')', ']', '}' then depth -= 1
      end
    end
    depth
  end
end
