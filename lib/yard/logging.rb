# frozen_string_literal: true
require 'logger'
require 'thread'

module YARD
  # Handles console logging for info, warnings and errors.
  # Uses the stdlib Logger class in Ruby for all the backend logic.
  class Logger < ::Logger
    class SuppressMessage < RuntimeError; end

    # Registers a custom code to log at a given severity level. Once this code
    # is registered, it can be used in {#add} to send structured log messages
    # with support for callbacks defined in an {.on_message} hook.
    #
    # @param code [Symbol] the new custom code
    # @param severity [Symbol] the severity to log this code as. Must be one
    #   of {SEVERITIES}.
    # @return [void]
    # @example Defining a custom logger code for a plugin error
    #   # Allows my plugin to log custom logger warnings
    #   YARD::Logger.register_code :invalid_record_declaration, :warn
    def self.register_code(code, severity)
      registered_codes[code] = severity
    end

    # Register a callback when a logging message is added for a given code (or
    # {SEVERITIES} level).
    #
    # @param code [Symbol, nil] the code to register the callback for. If a
    #   value from {SEVERITIES} is passed, the hook will be called for all
    #   messages at that log level, including messages from custom codes. If
    #   +nil+ (or +code+ is omitted), this hook is called for all messages.
    # @yieldparam data [Hash<Symbol, Object>] a bag of data passed in from
    #   {#add}. Also includes +:message+, +:code+, and +:severity+ keys from
    #   the add call with the string, custom code, and mapped severity respectively.
    #   Values in this hash can be modified to update the final logged details.
    # @yieldreturn [void]
    # @raise [SuppressMessage] raise this exception from the callback if you
    #   wish to suppress the logging message.
    # @example Suppressing a message for a custom log code
    #   YARD::Logger.on_message :unknown_tag do |data|
    #     raise YARD::Logger::SuppressMessage if data[:tag_name] == "special"
    #   end
    # @example Modifying a log message
    #   YARD::Logger.on_message :parse_error do |data|
    #     data[:message] = "PARSE ERROR!\n" + data[:error].backtrace.to_s
    #   end
    # @example Hooking into all warnings
    #   YARD::Logger.on_message :warn do |data|
    #     log.debug "A warning occurred: #{data[:message]}"
    #   end
    # @example Hooking into all messages
    #   YARD::Logger.on_message do |data|
    #     # cannot use log from here, will be infinite loop!
    #   end
    def self.on_message(code = nil, &block)
      (on_message_callbacks[code] ||= []) << block
    end

    # @return [Hash<Symbol, Symbol>] the map of structured codes to their
    #   respective {SEVERITIES} logging level. Do not modify this property
    #   directly, use {.register_code} instead.
    def self.registered_codes
      @registered_codes ||= {}
    end

    # @private
    def self.on_message_callbacks
      @on_message_callbacks ||= {}
    end

    # The list of characters displayed beside the progress bar to indicate
    # "movement".
    # @since 0.8.2
    PROGRESS_INDICATORS = ["\u230C", "\u230D", "\u230E", "\u230F"]

    # @return [IO] the IO object being logged to
    # @since 0.8.2
    def io; @logdev end
    def io=(pipe) @logdev = pipe end

    # @return [Boolean] whether backtraces should be shown (by default
    #   this is on).
    def show_backtraces; @show_backtraces || level == DEBUG end
    attr_writer :show_backtraces

    # @return [Boolean] whether progress indicators should be shown when
    #   logging CLIs (by default this is off).
    def show_progress
      return false if YARD.ruby18? # threading is too ineffective for progress support
      return false if YARD.windows? # windows has poor ANSI support
      return false unless io.tty? # no TTY support on IO
      return false unless level > INFO # no progress in verbose/debug modes
      @show_progress
    end
    attr_writer :show_progress

    # The logger instance
    # @return [Logger] the logger instance
    def self.instance(pipe = STDOUT)
      @logger ||= new(pipe)
    end

    # Creates a new logger
    def initialize(pipe, *args)
      super(pipe, *args)
      self.io = pipe
      self.show_backtraces = true
      self.show_progress = false
      self.level = WARN
      self.formatter = method(:format_log)
      @progress_indicator = 0
      @mutex = Mutex.new
    end

    # Changes the debug level to DEBUG if $DEBUG is set
    # and writes a debugging message.
    def debug(*args)
      self.level = DEBUG if $DEBUG
      super
    end

    # Captures the duration of a block of code for benchmark analysis. Also
    # calls {#progress} on the message to display it to the user.
    #
    # @todo Implement capture storage for reporting of benchmarks
    # @param [String] msg the message to display
    # @param [Symbol, nil] nontty_log the level to log as if the output
    #   stream is not a TTY. Use +nil+ for no alternate logging.
    # @yield a block of arbitrary code to benchmark
    # @return [void]
    def capture(msg, nontty_log = :debug)
      progress(msg, nontty_log)
      yield
    ensure
      clear_progress
    end

    # Displays a progress indicator for a given message. This progress report
    # is only displayed on TTY displays, otherwise the message is passed to
    # the +nontty_log+ level.
    #
    # @param [String] msg the message to log
    # @param [Symbol, nil] nontty_log the level to log as if the output
    #   stream is not a TTY. Use +nil+ for no alternate logging.
    # @return [void]
    # @since 0.8.2
    def progress(msg, nontty_log = :debug)
      send(nontty_log, msg) if nontty_log
      return unless show_progress
      icon = ""
      if defined?(::Encoding)
        icon = PROGRESS_INDICATORS[@progress_indicator] + " "
      end
      @mutex.synchronize do
        print("\e[2K\e[?25l\e[1m#{icon}#{msg}\e[0m\r")
        @progress_msg = msg
        @progress_indicator += 1
        @progress_indicator %= PROGRESS_INDICATORS.size
      end
      Thread.new do
        sleep(0.05)
        progress(msg + ".", nil) if @progress_msg == msg
      end
    end

    # Clears the progress indicator in the TTY display.
    # @return [void]
    # @since 0.8.2
    def clear_progress
      return unless show_progress
      print_no_newline("\e[?25h\e[2K")
      @progress_msg = nil
    end

    # Displays an unformatted line to the logger output stream, adding
    # a newline.
    # @param [String] msg the message to display
    # @return [void]
    # @since 0.8.2
    def puts(msg = '')
      print("#{msg}\n")
    end

    alias print_no_newline <<
    private :print_no_newline

    # Displays an unformatted line to the logger output stream.
    # @param [String] msg the message to display
    # @return [void]
    # @since 0.8.2
    def print(msg = '')
      clear_line
      print_no_newline(msg)
    end
    alias << print

    # Prints the backtrace +exc+ to the logger as error data.
    #
    # @param [Array<String>] exc the backtrace list
    # @param [Symbol] level_meth the level to log backtrace at
    # @return [void]
    def backtrace(exc, level_meth = :error)
      return unless show_backtraces
      send(level_meth, "#{exc.class.class_name}: #{exc.message}")
      send(level_meth, "Stack trace:" +
        exc.backtrace[0..5].map {|x| "\n\t#{x}" }.join + "\n")
    end

    # Warns that the Ruby environment does not support continuations. Applies
    # to JRuby, Rubinius and MacRuby. This warning will only display once
    # per Ruby process.
    #
    # @deprecated Continuations are no longer needed by YARD 0.8.0+.
    # @return [void]
    def warn_no_continuations
    end

    # Sets the logger level for the duration of the block
    #
    # @example
    #   log.enter_level(Logger::ERROR) do
    #     YARD.parse_string "def x; end"
    #   end
    # @param [Fixnum] new_level the logger level for the duration of the block.
    #   values can be found in Ruby's Logger class.
    # @yield the block with the logger temporarily set to +new_level+
    def enter_level(new_level = level)
      old_level = level
      self.level = new_level
      yield
    ensure
      self.level = old_level
    end

    # The default list of logger severity codes.
    SEVERITIES = [:debug, :info, :warn, :error, :fatal, :unknown]

    # @private
    SEVERITIES_MAP = SEVERITIES.inject({}) {|h, k| h[k] = true; h }

    # @overload add(code, *args)
    #   Adds a message to be logged either using a custom structured code, or a
    #   default logger severities. See {SEVERITIES} for a list of default
    #   severities.
    #
    #   @note If a custom structured code is used, it must first be registered via
    #     {.register_code}.
    #   @overload add(code, message = "")
    #     @param code [Symbol] the custom code or default severity code to log
    #       the message as. If a custom code is used, it must first be registered
    #       with {.register_code}.
    #     @param message [String] the string to log.
    #     @example
    #       log.add :unknown_tag, "unknown tag in #{object}"
    #   @overload add(code, opts = {}, &block)
    #     @note All messages returned in block form will have their space prefixes
    #       stripped away. This allows heredoc style <tt><<-eof</tt> formatting
    #       of long lines.
    #     @param code [Symbol] the custom code or default severity code to log
    #       the message as. If a custom code is used, it must first be registered
    #       with {.register_code}.
    #     @param opts [Hash] a custom structure of data to pass to any callbacks.
    #       registered to the logger. Also supports `:message` and `:code` to
    #       override their respective values.
    #     @option opts :message [String] the string to log (if no block is passed).
    #     @yield an optional block to provide a multi-line string message.
    #     @yieldreturn [String] if a block is supplied, return the string to log.
    #     @example Logging with custom data
    #       log.add :unknown_tag, object: object, file: object.file do
    #         "unknown tag in #{object}"
    #       end
    #   @see .register_code
    #   @see .on_message
    #   @return [void]
    def add(code, opts = {}, _progname = nil)
      if Fixnum === code # called by base class when actually logging
        clear_line
        return super
      end

      case opts
      when String
        opts = {:message => opts}
      when Hash
        opts = opts.dup
        opts[:message] ||= block_given? ? clean_block_message(yield) : ""
      end
      opts[:code] = code

      if SEVERITIES_MAP[code]
        opts[:severity] = code
      else
        opts[:severity] = self.class.registered_codes[code]
        if opts[:severity].nil?
          add(DEBUG, "logging warning for unknown code: #{code}")
          opts[:severity] = :warn
        elsif !call_log_callbacks(opts, [code])
          return
        end
      end

      send(opts[:severity], opts[:message])
    end

    [:debug, :warn, :error, :fatal, :info, :unknown].each do |severity|
      alias_method "#{severity}_without_callback", severity
      private "#{severity}_without_callback"
      define_method(severity) do |msg = ""|
        opts = {:severity => severity, :message => msg, :code => severity}
        if call_log_callbacks(opts, [severity, nil])
          send("#{severity}_without_callback", msg)
        end
      end
    end

    private

    # @raise [SuppressMessage] if message should be suppressed by logger
    def call_log_callbacks(opts, list)
      should_log = true

      list.uniq.each do |type|
        self.class.on_message_callbacks.fetch(type, []).each do |cb|
          begin
            cb.call(opts)
          rescue SuppressMessage
            should_log = false
          end
        end
      end

      should_log
    end

    def clean_block_message(message)
      message.gsub(/\n +/, "\n").strip
    end

    def clear_line
      return unless @progress_msg
      print_no_newline("\e[2K\r")
    end

    # Log format (from Logger implementation). Used by Logger internally
    def format_log(sev, _time, _prog, msg)
      "[#{sev.downcase}]: #{msg}\n"
    end
  end
end
