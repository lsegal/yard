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
end
