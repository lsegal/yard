module YARD
  # Handles all logic for complex lexical and inherited object resolution.
  # Used by {Registry.resolve}, so there is no need to use this class
  # directly.
  #
  # @see Registry.resolve
  # @since 0.9.1
  class RegistryResolver
    include CodeObjects::NamespaceMapper

    # Creates a new resolver object for a registry.
    #
    # @param registry [Registry] only set this if customizing the registry
    #   object
    def initialize(registry = Registry)
      @registry = Registry
    end

    # Performs a lookup on a given path in the registry. Resolution will occur
    # in a similar way to standard Ruby identifier resolution, doing lexical
    # lookup, as well as (optionally) through the inheritance chain. A proxy
    # object can be returned if the lookup fails for future resolution. The
    # proxy will be type hinted with the +type+ used in the original lookup.
    #
    # @option opts namespace [CodeObjects::Base, :root, nil] (nil) the namespace
    #   object to start searching from. If root or nil is provided, {Registry.root}
    #   is assumed.
    # @option opts inheritance [Boolean] (false) whether to perform lookups through
    #   the inheritance chain (includes mixins)
    # @option opts proxy_fallback [Boolean] (false) when true, a proxy is returned
    #   if no match is found
    # @option opts type [Symbol] (nil) an optional type hint for the resolver
    #   to consider when performing a lookup. If a type is provided and the
    #   resolved object's type does not match the hint, the object is discarded.
    # @return [CodeObjects::Base, CodeObjects::Proxy, nil] the first object
    #   that matches the path lookup. If proxy_fallback is provided, a proxy
    #   object will be returned in the event of no match, otherwise nil will
    #   be returned.
    # @example A lookup from root
    #   resolver.lookup_by_path("A::B::C")
    # @example A lookup from the A::B namespace
    #   resolver.lookup_by_path("C", namespace: P("A::B"))
    # @example A lookup on a method through the inheritance tree
    #   resolver.lookup_by_math("A::B#foo", inheritance: true)
    def lookup_by_path(path, opts = {})
      path = path.to_s
      namespace = opts[:namespace]
      inheritance = opts[:inheritance] || false
      proxy_fallback = opts[:proxy_fallback] || false
      type = opts[:type]

      if namespace.is_a?(CodeObjects::Proxy)
        return proxy_fallback ? CodeObjects::Proxy.new(namespace, path, type) : nil
      end

      if namespace == :root || !namespace
        namespace = @registry.root
      else
        namespace = namespace.parent until namespace.is_a?(CodeObjects::NamespaceObject)
      end
      orignamespace = namespace

      if path =~ /\A#{default_separator}/
        path, namespace = $', @registry.root
      end

      resolved = nil
      while namespace && !resolved
        resolved = lookup_path_direct(namespace, path, type)
        resolved ||= lookup_path_inherited(namespace, path, type) if inheritance
        namespace = namespace.parent
      end

      if proxy_fallback
        resolved ||= CodeObjects::Proxy.new(orignamespace, path, type)
      end

      resolved
    end

    private

    # return [Boolean] if the obj's type matches the provided type.
    def validate(obj, type)
      return !type || (obj && obj.type == type) ? obj : nil
    end

    # Performs a lexical lookup from a namespace for a path and a type hint.
    def lookup_path_direct(namespace, path, type)
      if namespace.root? && result = validate(@registry.at(path), type)
        return result
      end

      if path =~ /\A(#{separators_match})/
        return validate(@registry.at(namespace.path + path), type)
      end

      separators.each do |sep|
        result = validate(@registry.at(namespace.path + sep + path), type)
        return result if result
      end

      nil
    end

    # Performs a lookup through the inheritance chain on a path with a type hint.
    def lookup_path_inherited(namespace, path, type)
      resolved, last_obj, scopes, last_sep, pos = nil, namespace, [], nil, 0

      if path =~ /\A(#{separators_match})/
        last_sep, path = $1, $'
      end

      path.scan(/(.+?)(#{separators_match}|$)/).each do |part, sep|
        cur_obj = nil
        pos += "#{part}#{sep}".length
        parsed_end = pos == path.length

        if !last_obj || (!parsed_end && !last_obj.is_a?(CodeObjects::NamespaceObject))
          break # can't continue
        end

        collect_namespaces(last_obj).each do |ns|
          next if ns.is_a?(CodeObjects::Proxy)

          found, search_seps = nil, []
          scopes.each do |scope|
            search_seps += separators_for_type(scope)
          end

          if search_seps.empty?
            if ns.type == :root
              search_seps = [""]
            elsif last_sep.nil?
              search_seps = separators
            else
              search_seps = [@default_sep]
            end
          end

          ([last_sep] | search_seps).compact.each do |search_sep|
            break if found = @registry.at(ns.path + search_sep.to_s + part) 
          end

          break cur_obj = found if found
        end

        last_sep = sep
        scopes = types_for_separator(sep) || []
        last_obj = cur_obj
        resolved = cur_obj if parsed_end && cur_obj && (type.nil? || type == cur_obj.type)
      end

      resolved
    end

    # Collects and returns all inherited namespaces for a given object
    def collect_namespaces(object)
      return [] unless object.respond_to?(:inheritance_tree)

      nss = object.inheritance_tree(true)
      if object.respond_to?(:superclass)
        if object.superclass != P('BasicObject')
          nss |= [P('Object')]
        end
        nss |= [P('BasicObject')]
      end

      nss
    end
  end
end
