require File.dirname(__FILE__) + '/spec_helper'

describe YARD::Handlers::ExtendHandler do
  before { parse_file :extend_handler_001, __FILE__ }

  it "should include modules at class scope" do
    Registry.at(:B).mixins(:class).should include(P(:A))
    Registry.at(:B).mixins(:instance).should be_empty
  end
end
