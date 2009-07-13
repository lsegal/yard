require File.dirname(__FILE__) + '/spec_helper'

def html_equals(result, expected)
  [expected, result].each do |value|
    value.gsub!(/(>)\s+|\s+(<)/, '\1\2')
    value.strip!
  end
  result.should == expected
end

describe Template.template(:default, :method) do
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
        </div><div class="deprecated"> 
          <p> 
            <strong>Deprecated.</strong> <em>for great justice</em> 
          </p> 
        </div> 
        <div class="docstring">Comments</div>
        <div class="tags"> 
          <div class="param"> 
            <h3>Parameters:</h3> 
            <dl> 
              <dt> 
                <span class='type'>[<tt>String</tt>]</span> 
                <span class='name'>x</span> 
              </dt>
              <dd><span class='desc'>the x argument</span></dd> 
            </dl> 
          </div>
          <div class="return"> 
            <h3>Returns:</h3> 
            <dl> 
              <dt> 
                <span class='type'>[<tt>String</tt>]</span> 
                <span class='name'></span> 
              </dt> 
              <dd><span class='desc'>the result</span></dd> 
            </dl> 
          </div> 
        </div>
        <div class="section source"> 
          <span>[<a class="source_link" href="#">View source</a>]</span> 
          <div class="source_code"> 
            <table> 
              <tr> 
                <td><pre class="lines">6</pre></td> 
                <td><pre class="code"><span class="info file"># File '(stdin)', line 6</span> 
                <span class='kw'>def</span> <span class='id m'>m</span>
                <span class='lparen'>(</span><span class='id x'>x</span>
                <span class='rparen'>)</span> <span class='kw'>end</span></pre></td> 
              </tr> 
            </table> 
          </div> 
        </div> 
      </div>
    eof
  end
end