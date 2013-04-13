require File.dirname(__FILE__) + '/../spec_helper'

describe YARD::CLI::Display do
  it "displays an object" do
    Registry.stub(:load)
    foo = CodeObjects::ClassObject.new(:root, :Foo)
    foo.docstring = 'Foo bar'
    output = foo.format

    YARD::CLI::Display.run('-f', 'text', 'Foo')
    log.io.string.strip.should eq(output.strip)
  end
end
