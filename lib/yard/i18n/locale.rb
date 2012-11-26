module YARD
  module I18n
    # +Locale+ is a unit of translation. It has {#name} and a set of
    # messages.
    #
    # @since 0.8.2
    class Locale
      class << self
        # @return [String, nil] the default locale name.
        # @since 0.8.4
        attr_accessor :default

        undef default
        def default
          @@default ||= nil
        end

        undef default=
        def default=(locale)
          @@default = locale
        end
      end

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
      # @return [String] translated message. If tarnslation isn't
      #   registered, the +message+ is returned.
      def translate(message)
        @messages[message] || message
      end
    end
  end
end
