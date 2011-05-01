module YARD
  module CodeObjects
    # A MacroObject represents a docstring defined through +@macro NAME+ and can be
    # reused by specifying the tag +@macro NAME+. You can also provide the
    # +attached+ type flag to the macro definition to have it attached to the
    # specific DSL method so it will be implicitly reused.
    # 
    # @example Creating a basic named macro
    #   # @macro prop
    #   # @method $1(${3-})
    #   # @return [$2] the value of the $0
    #   property :foo, String, :a, :b
    #   
    #   # @macro prop
    #   property :bar, Numeric, :value
    # 
    # @example Creating a macro that is attached to the method call
    #   # @macro [attach] prop2
    #   # @method $1(value)
    #   property :foo
    #   
    #   # Extra data added to docstring
    #   property :bar
    class MacroObject < Base
      MACRO_MATCH = /(\\)?\$(?:\{(-?\d+|\*)(-)?(-?\d+)?\}|(-?\d+|\*))/

      class << self
        def create(macro_name, data, method_object = nil)
          obj = new(:root, macro_name)
          obj.macro_data = data
          obj.method_object = method_object
          obj
        end
    
        def find(macro_name)
          Registry.at('.macro.' + macro_name.to_s)
        end
      
        def find_or_create(data, method_object = nil)
          docstring = Docstring === data ? data : Docstring.new(data)
          return unless docstring.tag(:macro)
          return unless name = macro_name(docstring)
          if new_macro?(docstring)
            method_object = nil unless attached_macro?(docstring, method_object)
            create(name, macro_data(docstring), method_object)
          else
            find(name)
          end
        end
        alias create_docstring find_or_create
        
        def apply(docstring, args = [], line_source = '', block_source = '', method_object = nil)
          macro = find_or_create(docstring, method_object)
          apply_macro(macro, docstring, args, line_source, block_source)
        end
        
        def apply_macro(macro, docstring, args = [], line_source = '', block_source = '')
          docstring = Docstring.new(docstring) unless Docstring === docstring
          data = []
          data << macro.expand(args, line_source, block_source) if macro
          if !macro && new_macro?(docstring)
            data << expand(macro_data(docstring), args, line_source, block_source)
          end
          data << nonmacro_data(docstring)
          data.join("\n").strip
        end
        
        def expand(macro_data, call_params = [], full_source = '', block_source = '')
          macro_data = macro_data.all if macro_data.is_a?(Docstring)
          macro_data.gsub(MACRO_MATCH) do
            escape, first, last, rng = $1, $2 || $5, $4, $3 ? true : false
            next $&[1..-1] if escape
            if first == '*'
              last ? $& : full_source
            else
              first_i = first.to_i
              last_i = (last ? last.to_i : call_params.size)
              last_i = first_i unless rng
              params = call_params[first_i..last_i]
              params ? params.join(", ") : ''
            end
          end
        end
      
        private
      
        def new_macro?(docstring)
          if docstring.tag(:macro) 
            if types = docstring.tag(:macro).types
              return true if types.include?('new') || types.include?('attach')
            end
            if docstring.all =~ MACRO_MATCH
              return true
            end
          end
          false
        end
        
        def attached_macro?(docstring, method_object)
          return false if method_object.nil?
          return false if docstring.tag(:macro).types.nil?
          docstring.tag(:macro).types.include?('attach')
        end
        
        def macro_name(docstring)
          docstring.tag(:macro).name
        end
        
        def macro_data(docstring)
          new_docstring = docstring.dup
          new_docstring.delete_tags(:macro)
          tag_text = docstring.tag(:macro).text
          if !tag_text || tag_text.strip.empty?
            new_docstring.to_raw.strip
          else
            tag_text
          end
        end
        
        def nonmacro_data(docstring)
          if new_macro?(docstring)
            text = docstring.tag(:macro).text
            return '' if !text || text.strip.empty?
          end
          new_docstring = docstring.dup
          new_docstring.delete_tags(:macro)
          new_docstring.to_raw
        end
      end
    
      attr_accessor :macro_data
      attr_accessor :method_object
    
      def attached?; method_object ? true : false end
      def path; '.macro.' + name.to_s end
      def sep; '.' end
      
      def expand(call_params = [], full_source = '', block_source = '')
        self.class.expand(macro_data, call_params, full_source, block_source)
      end
    end
  end
end