require File.dirname(__FILE__) + '/../spec_helper'

def html_equals(result, expected)
  [expected, result].each do |value|
    value.gsub!(/(>)\s+|\s+(<)/, '\1\2')
    value.strip!
  end
  expected.should == result
end

describe Tadpole.template(:default, :method, :html) do
  before do
    YARD.parse_string <<-eof
      private
      # Comments
      # @param [String] x the x argument
      # @return [String] the result
      # @deprecated for great justice
      def m(x) end
      alias x m
    eof
  end
  
  it "should render correctly" do
    html_equals(Registry.at('#m').format(:format => :html), <<-'eof')
      <div id="m-instance_method" class="section method">
        <div class="details_title">
          <div class='section method'>
            <tt class='def'>
              <span class='visibility'>private</span>
              <span class='return_types'><tt>String</tt></span>
              <span class='name'>m</span><span class='args'>(x)</span>
              <span class='block'></span>
            </tt>
          </div>
          <p class="aliases">
            <span class="aka">Also known as:</span>
            <tt id="x-instance_method">x</tt>
          </p>
        </div>
        <div class="section deprecated">
          <p>
            <strong>Deprecated.</strong> <em>for great justice</em>
          </p>
        </div>
        <div class="section docstring">Comments</div>
      </div>
    eof
  end
end