require File.dirname(__FILE__) + '/spec_helper'

include Parser

describe YARD::Handlers::Base do
  describe "#handles and inheritance" do
    before do
      Handlers::Base.stub!(:inherited)
    end
  
    it "should keep track of subclasses" do
      Handlers::Base.should_receive(:inherited).once
      class TestHandler < Handlers::Base; end
    end
  
    it "should raise NotImplementedError if process is called on a class with no #process" do
      class TestNotImplementedHandler < Handlers::Base
      end
    
      lambda { TestNotImplementedHandler.new(0, 0).process }.should raise_error(NotImplementedError)
    end
  
    it "should allow multiple handles arguments" do
      Handlers::Base.should_receive(:inherited).once
      class TestHandler1 < Handlers::Base
        handles :a, :b, :c
      end
      TestHandler1.handlers.should == [:a, :b, :c]
    end

    it "should allow multiple handles calls" do
      Handlers::Base.should_receive(:inherited).once
      class TestHandler2 < Handlers::Base
        handles :a
        handles :b
        handles :c
      end
      TestHandler2.handlers.should == [:a, :b, :c]
    end
  end
  
  describe 'transitive tags' do
    it "should add transitive tags to children" do
      Registry.clear
      YARD.parse_string <<-eof
        # @since 1.0
        # @author Foo
        class A
          def foo; end
          # @since 1.1
          def bar; end
        end
      eof
      Registry.at('A').tag(:since).text.should == "1.0"
      Registry.at('A#foo').tag(:since).text.should == "1.0"
      Registry.at('A#bar').tag(:since).text.should == "1.1"
      Registry.at('A#bar').tag(:author).should be_nil
    end
  end
  
  describe '#push_state' do
    def process(klass)
      state = OpenStruct.new(:namespace => "ROOT", :scope => :instance, :owner => "ROOT")
      klass.new(state, nil).process
    end
    
    it "should push and return all old state info after block" do
      class PushStateHandler1 < Handlers::Base
        def process
          push_state(:namespace => "FOO", :scope => :class, :owner => "BAR") do
            namespace.should == "FOO"
            scope.should == :class
            owner.should == "BAR"
          end
          namespace.should == "ROOT"
          owner.should == "ROOT"
          scope.should == :instance
        end
      end
      process PushStateHandler1
    end
    
    it "should allow owner to be pushed individually" do
      class PushStateHandler2 < Handlers::Base
        def process
          push_state(:owner => "BAR") do
            namespace.should == "ROOT"
            scope.should == :instance
            owner.should == "BAR"
          end
          owner.should == "ROOT"
        end
      end
      process PushStateHandler2
    end
    
    it "should allow scope to be pushed individually" do
      class PushStateHandler3 < Handlers::Base
        def process
          push_state(:scope => :foo) do
            namespace.should == "ROOT"
            scope.should == :foo
            owner.should == "ROOT"
          end
          scope.should == :instance
        end
      end
      process PushStateHandler3
    end
  end
  
  describe '.in_file' do
    def parse(filename, src = "class A; end")
      parser = Parser::SourceParser.new
      parser.instance_variable_set("@file", filename)
      parser.parse(StringIO.new(src))
    end
    
    def create_handler(stmts)
      @@counter ||= 0
      sklass = Parser::SourceParser.parser_type == :ruby ? "Base" : "Legacy::Base"
      instance_eval(<<-eof)
        class ::InFileHandler#{@@counter += 1} < Handlers::Ruby::#{sklass}
          handles /^class/
          #{stmts}
          def process; MethodObject.new(:root, :FOO) end
        end
      eof
    end
    
    def test_handler(file, stmts, creates = true)
      Registry.clear
      Registry.at('#FOO').should be_nil
      create_handler(stmts)
      parse(file)
      Registry.at('#FOO').send(creates ? :should_not : :should, be_nil)
      Handlers::Base.subclasses.delete_if {|k,v| k.to_s =~ /^InFileHandler/ }
    end
    
    [:ruby, :ruby18].each do |parser_type|
      next if parser_type == :ruby && LEGACY_PARSER
      describe "Parser type = #{parser_type.inspect}" do
        Parser::SourceParser.parser_type = parser_type
        it "should allow handler to be specific to a file" do
          test_handler 'file_a.rb', 'in_file "file_a.rb"', true
        end
        
        it "should ignore handler if filename does not match" do
          test_handler 'file_b.rb', 'in_file "file_a.rb"', false
        end

        it "should only test filename part when given a String" do
          test_handler '/path/to/file_a.rb', 'in_file "/to/file_a.rb"', false
        end
        
        it "should test exact match for entire String" do
          test_handler 'file_a.rb', 'in_file "file"', false
        end

        it "should allow a Regexp as argument and test against full path" do
          test_handler 'file_a.rbx', 'in_file /\.rbx$/', true
          test_handler '/path/to/file_a.rbx', 'in_file /\/to\/file_/', true
          test_handler '/path/to/file_a.rbx', 'in_file /^\/path/', true
        end

        it "should allow multiple in_file declarations" do
          stmts = 'in_file "x"; in_file /y/; in_file "foo.rb"'
          test_handler 'foo.rb', stmts, true
          test_handler 'xyzzy.rb', stmts, true
          test_handler 'x', stmts, true
        end
      end
    end
  end
end
