module YARD
  module I18n
    # +Locale+ is a unit of translation. It has {#name} and a set of
    # messages.
    #
    # @since 0.8.2
    class Locale
      # @return [String] the name of the locale. It used IETF language
      #   tag format +[language[_territory][.codeset][@modifier]]+.
      # @see http://tools.ietf.org/rfc/bcp/bcp47.txt
      #   BCP 47 - Tags for Identifying Languages
      attr_reader :name

      # Creates a locale for +name+ locale.
      #
      # @param [String] name the locale name.
      def initialize(name)
        @name = name
        @messages = {}
      end

      # Loads translation messages from +locale_directory+/{#name}.po.
      #
      # @param [String] locale_directory the directory path that has
      #   {#name}.po.
      # @return [Boolean] +true+ if PO file exists, +false+ otherwise.
      def load(locale_directory)
        return false if @name.nil?

        po_file = File.join(locale_directory, "#{@name}.po")
        return false unless File.exist?(po_file)

        begin
          require "gettext/tools/poparser"
          require "gettext/runtime/mofile"
        rescue LoadError
          log.warn "Need gettext gem for i18n feature:"
          log.warn "  gem install gettext"
          return false
        end

        parser = GetText::PoParser.new
        parser.report_warning = false
        data = GetText::MoFile.new
        parser.parse_file(po_file, data)
        @messages.merge!(data)
        true
      end

      # @param [String] message the translation target message.
      # @return [String] translated message. If translation isn't
      #   registered or target message isn't translated,
      #   the +message+ is returned.
      def translate(message)
        return message if @messages[message].nil?    # not registered
        return message if @messages[message].empty?  # not translated

        @messages[message]
      end
    end
  end
end
