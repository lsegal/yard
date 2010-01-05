require File.dirname(__FILE__) + '/../spec_helper'

#described_in_docs String, '#camelcase'
#described_in_docs String, '#underscore'

describe String do
  describe '#underscore' do
    it 'should turn HelloWorld into hello_world' do
      "HelloWorld".underscore.should == "hello_world"
    end
  
    it "should turn Hello::World into hello/world" do
      "Hello::World".underscore.should == "hello/world"
    end
  end

  describe '#camelcase' do
    it 'should turn hello_world into HelloWorld' do
      "hello_world".camelcase.should == "HelloWorld"
    end

    it "should turn hello/world into Hello::World" do
      "hello/world".camelcase.should == "Hello::World"
    end
    
    it "should not camelcase _foo" do
      "_foo".camelcase.should == "_foo"
    end
  end
  
  describe '#shell_split' do
    it "should split simple non-quoted text" do
      "a b c".shell_split.should == %w(a b c)
    end
    
    it "should split double quoted text into single token" do
      'a "b c d" e'.shell_split.should == ["a", "b c d", "e"]
    end
    
    it "should split single quoted text into single token" do
      "a 'b c d' e".shell_split.should == ["a", "b c d", "e"]
    end
    
    it "should handle escaped quotations in quotes" do
      "'a \\' b'".shell_split.should == ["a ' b"]
    end
    
    it "should handle escaped quotations outside quotes" do
      "\\'a 'b'".shell_split.should == %w('a b)
    end
    
    it "should handle escaped backslash" do
      "\\\\'a b c'".shell_split.should == ['\a b c']
    end
    
    it "should handle any whitespace as space" do
      text = "foo\tbar\nbaz\r\nfoo2 bar2"
      text.shell_split.should == %w(foo bar baz foo2 bar2)
    end

    it "should handle complex input" do
      text = "hello \\\"world \"1 2\\\" 3\" a 'b \"\\\\\\'' c"
      text.shell_split.should == ["hello", "\"world", "1 2\" 3", "a", "b \"\\'", "c"]
    end
  end
end