require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ExtendHandler do
  before { parse_file :extend_handler_001, __FILE__ }

  it "should include modules at class scope" do
    Registry.at(:B).class_mixins.should include(P(:A))
    Registry.at(:B).instance_mixins.should be_empty
  end

  it "should handle a module extending itself" do
    Registry.at(:C).class_mixins.should include(P(:C))
    Registry.at(:C).instance_mixins.should be_empty
  end
end
