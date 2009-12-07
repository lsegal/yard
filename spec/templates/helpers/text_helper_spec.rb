require File.dirname(__FILE__) + '/../../spec_helper'
require File.dirname(__FILE__) + "/shared_signature_examples"

describe YARD::Templates::Helpers::TextHelper do
  include YARD::Templates::Helpers::TextHelper
  include YARD::Templates::Helpers::MethodHelper
  
  describe '#signature' do
    before do
      @results = {
        :regular => "root.foo -> Object",
        :default_return => "root.foo -> Hello",
        :no_default_return => "root.foo",
        :private_class => "A.foo -> Object (private)",
        :single => "root.foo -> String",
        :two_types => "root.foo -> (String, Symbol)",
        :two_types_multitag => "root.foo -> (String, Symbol)",
        :type_nil => "root.foo -> Type?",
        :type_array => "root.foo -> Type+",
        :multitype => "root.foo -> (Type, ...)",
        :void => "root.foo -> void",
        :hide_void => "root.foo",
        :block => "root.foo {|a, b, c| ... } -> Object"
      }
    end
    
    def signature(obj) super(obj).strip end
    
    it_should_behave_like "signature"
  end
end