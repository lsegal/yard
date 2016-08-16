# frozen_string_literal: true
require File.join(File.dirname(__FILE__), "spec_helper")

describe YARD::Logger do
  describe "#show_backtraces" do
    it "is true if debug level is on" do
      log.show_backtraces = true
      log.enter_level(Logger::DEBUG) do
        log.show_backtraces = false
        expect(log.show_backtraces).to be true
      end
      expect(log.show_backtraces).to be false
    end
  end

  describe "#backtrace" do
    before { log.show_backtraces = true }
    after  { log.show_backtraces = false }

    it "logs backtrace in error by default" do
      expect(log).to receive(:error).with("RuntimeError: foo")
      expect(log).to receive(:error).with("Stack trace:\n\tline1\n\tline2\n")
      exc = RuntimeError.new("foo")
      exc.set_backtrace(['line1', 'line2'])
      log.enter_level(Logger::INFO) { log.backtrace(exc) }
    end

    it "allows backtrace to be entered in other modes" do
      expect(log).to receive(:warn).with("RuntimeError: foo")
      expect(log).to receive(:warn).with("Stack trace:\n\tline1\n\tline2\n")
      exc = RuntimeError.new("foo")
      exc.set_backtrace(['line1', 'line2'])
      log.enter_level(Logger::INFO) { log.backtrace(exc, :warn) }
    end
  end

  describe "#add" do
    before do
      @callbacks = YARD::Logger.on_message_callbacks
      @codes = YARD::Logger.codes
      @calls = []
      @expect_calls = []
    end

    after do
      YARD::Logger.codes.clear.replace(@codes)
      YARD::Logger.on_message_callbacks.clear.replace(@callbacks)
      expect(@calls).to eq(@expect_calls) unless @expect_calls.empty?
    end

    def expect_called(code)
      @expect_calls << code
      YARD::Logger.on_message(code) { @calls << code }
    end

    it 'can use severities for code' do
      log.add(:warn) { 'message' }
      expect(log.io.string).to match(/warn.*message/)
    end

    it 'allows 2nd param to be a string' do
      log.add :warn, 'message'
      expect(log.io.string).to match(/warn.*message/)
    end

    it 'allows 1st param to be a hash' do
      log.add(:code => :warn, :object => 'data') { 'message' }
      expect(log.io.string).to match(/warn.*message/)
    end

    it 'allows :message to be in opts' do
      log.add(:warn, :object => 'data') { 'message' }
      expect(log.io.string).to match(/warn.*message/)
    end

    it 'allows empty message' do
      expect_called(:warn)
      log.add :warn
    end

    it 'strips extra space from message in block' do
      log.add :warn do
        <<-eof
        MESSAGE
        ONE
        TWO
          \tTHREE
        eof
      end
      expect(log.io.string).to match("[warn]: MESSAGE\nONE\nTWO\n\tTHREE\n")
    end

    it 'calls callback for code' do
      YARD::Logger.register_code :test_code, :error
      expect_called(:test_code)
      log.add :test_code, 'message'
    end

    it 'passes options data to callback' do
      YARD::Logger.register_code :test_code, :warn

      called = false
      YARD::Logger.on_message :test_code do |data|
        called = true
        expect(data[:message]).to eq 'message'
        expect(data[:code]).to eq :test_code
        expect(data[:severity]).to eq :warn
        expect(data[:object]).to eq 'object'
      end

      log.add :test_code, :object => 'object' do
        'message'
      end
      expect(called).to eq true
    end

    it 'still calls callback for severity' do
      YARD::Logger.register_code :test_code, :error
      expect_called(:error)
      log.add :test_code, 'message'
    end

    it 'always calls catch-all callback' do
      YARD::Logger.register_code :test_code, :error
      expect_called(nil)
      log.add :test_code, 'message'
    end

    it 'allows callbacks to modify logger data' do
      YARD::Logger.register_code :test_code, :warn
      YARD::Logger.on_message :test_code do |data|
        data[:message] = data[:object] + "bar"
        data[:severity] = :fatal
      end

      log.add :test_code, :object => 'foo'
      expect(log.io.string).to eq "[fatal]: foobar\n"
    end

    it 'can suppress a log message in a callback' do
      YARD::Logger.register_code :test_code, :warn
      YARD::Logger.on_message :test_code do
        raise YARD::Logger::SuppressMessage
      end

      called = false
      YARD::Logger.on_message(:warn) { called = true }

      log.add :test_code, 'message'
      expect(log.io.string).to be_empty
      expect(called).to eq false
    end

    it 'calls all callback at a given level when suppressing' do
      YARD::Logger.register_code :test_code, :warn
      YARD::Logger.on_message(:test_code) { log.io.print 'a' }
      YARD::Logger.on_message(:test_code) { raise YARD::Logger::SuppressMessage }
      YARD::Logger.on_message(:test_code) { log.io.print 'b' }
      YARD::Logger.on_message(:test_code) { log.io.print 'c' }

      log.add :test_code, 'message'
      expect(log.io.string).to eq 'abc'
    end

    it 'debugs a warning (before logging code) if unknown code is used' do
      log.enter_level(Logger::DEBUG) do
        log.add :unknown_code, '!!message!!'
        expect(log.io.string).to match(/logging warning for unknown code: unknown_code/)
        expect(log.io.string).to match(/!!message!!/)
      end
    end
  end
end
