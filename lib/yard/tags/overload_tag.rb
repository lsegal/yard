module YARD
  module Tags
    class OverloadTag < Tag
      attr_reader :signature, :parameters, :docstring
      
      def initialize(tag_name, text, raw_text)
        super(tag_name, nil)
        parse_tag(raw_text)
        parse_signature
      end
      
      def tag(name) docstring.tag(name) end
      def tags(name = nil) docstring.tags(name) end
      def has_tag?(name) docstring.has_tag?(name) end
        
      def object=(value)
        super(value)
        @docstring = Docstring.new(@docstring, value) if @docstring.class == String
      end
        
      private
      
      def parse_tag(raw_text)
        @signature, @docstring = raw_text.split(/\r?\n/, 2)
        numspaces = @docstring[/\A(\s*)/, 1].length
        @docstring.gsub!(/^\s{#{numspaces}}/, '').strip!
        @signature.strip!
      end
      
      def parse_signature
        if signature =~ /^(?:def)?\s*(#{CodeObjects::METHODMATCH})(?:(?:\s+|\s*\()(.*)(?:\)\s*$)?)?/m
          meth, args = $1, $2
          meth.gsub!(/\s+/,'')
          # FIXME refactor this code to not make use of the Handlers::Base class (tokval_list should be moved)
          args = YARD::Handlers::Base.new(nil, nil).send(:tokval_list, YARD::Parser::TokenList.new(args), :all)
          args.map! {|a| k, v = *a.split('=', 2); [k.strip.to_sym, (v ? v.strip : nil)] } if args
          @name = meth.to_sym
          @parameters = args
        end
      end
    end
  end
end
