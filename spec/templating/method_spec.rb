require File.dirname(__FILE__) + '/spec_helper'

def html_equals(result, expected)
  [expected, result].each do |value|
    value.gsub!(/(>)\s+|\s+(<)/, '\1\2')
    value.strip!
  end
  result.should == expected
end

describe Template.template(:default, :method) do
  before { Registry.clear }
  
  def source(line)
  end

  describe 'regular (deprecated) method' do
    it "should render correctly" do
      YARD.parse_string <<-'eof'
        private
        # Comments
        # @param [String] x the x argument
        # @return [String] the result
        # @deprecated for great justice
        def m(x) end
        alias x m
      eof

      html_equals(Registry.at('#m').format(:format => :html), <<-'eof')
        <div id="m-instance_method" class="section method"> 
          <div class="details_title"> 
            <div class='section signature'> 
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
            <div class="source_code" style="display: none"> 
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
  
  describe 'method with 1 overload' do
    it "should render correctly" do
      YARD.parse_string <<-'eof'
        private
        # Comments
        # @overload m(x, y)
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        def m(x) end
      eof

      html_equals(Registry.at('#m').format(:format => :html), <<-'eof')
        <div id="m-instance_method" class="section method"> 
          <div class="details_title"> 
            <div class='section signature'> 
              <tt class='def'> 
                <span class='visibility'>private</span> 
                <span class='return_types'></span> 
                <span class='name'>m</span><span class='args'>(x, y)</span> 
                <span class='block'></span> 
              </tt> 
            </div> 
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
                <dd><span class='desc'>parameter x</span></dd> 
                <dt> 
                  <span class='type'>[<tt>Boolean</tt>]</span> 
                  <span class='name'>y</span> 
                </dt>
                <dd><span class='desc'>parameter y</span></dd> 
              </dl> 
            </div>
          </div>
          <div class="section source"> 
            <span>[<a class="source_link" href="#">View source</a>]</span> 
            <div class="source_code" style="display: none"> 
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
  
  describe 'method with 2 overloads' do
    it "should render correctly" do
      YARD.parse_string <<-'eof'
        private
        # Method comments
        # @overload m(x, y)
        #   Overload docstring
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        # @overload m(x, y, z)
        #   @param [String] x parameter x
        #   @param [Boolean] y parameter y
        #   @param [Boolean] z parameter z
        def m(*args) end
      eof

      html_equals(Registry.at('#m').format(:format => :html), <<-'eof')
        <div id="m-instance_method" class="section method"> 
          <div class="details_title"> 
            <div class='section signature'> 
              <tt class='def'> 
                <span class='visibility'>private</span> 
                <span class='return_types'></span> 
                <span class='name'>m</span><span class='args'>(*args)</span> 
                <span class='block'></span> 
              </tt> 
            </div> 
          </div>
          <div class="docstring">Method comments</div>
          <div class="tags"></div>
          <div id="m-instance_method_overload2" class="section method overload"> 
            <div class="details_title"> 
              <div class='section signature'> 
                <tt class='def'> 
                  <span class='return_types'></span> 
                  <span class='name'>m</span><span class='args'>(x, y)</span> 
                  <span class='block'></span> 
                </tt> 
              </div> 
            </div>
            <div class="docstring">Overload docstring</div>
            <div class="tags">
              <div class="param">
                <h3>Parameters:</h3> 
                <dl> 
                  <dt> 
                    <span class='type'>[<tt>String</tt>]</span> 
                    <span class='name'>x</span> 
                  </dt>
                  <dd><span class='desc'>parameter x</span></dd> 
                  <dt> 
                    <span class='type'>[<tt>Boolean</tt>]</span> 
                    <span class='name'>y</span> 
                  </dt>
                  <dd><span class='desc'>parameter y</span></dd> 
                </dl> 
              </div>
            </div>
          </div>
          <div id="m-instance_method_overload3" class="section method overload"> 
            <div class="details_title"> 
              <div class='section signature'> 
                <tt class='def'> 
                  <span class='return_types'></span> 
                  <span class='name'>m</span><span class='args'>(x, y, z)</span> 
                  <span class='block'></span> 
                </tt> 
              </div> 
            </div>
            <div class="docstring"></div>
            <div class="tags">
              <div class="param">
                <h3>Parameters:</h3> 
                <dl> 
                  <dt> 
                    <span class='type'>[<tt>String</tt>]</span> 
                    <span class='name'>x</span> 
                  </dt>
                  <dd><span class='desc'>parameter x</span></dd> 
                  <dt> 
                    <span class='type'>[<tt>Boolean</tt>]</span> 
                    <span class='name'>y</span> 
                  </dt>
                  <dd><span class='desc'>parameter y</span></dd> 
                  <dt> 
                    <span class='type'>[<tt>Boolean</tt>]</span> 
                    <span class='name'>z</span> 
                  </dt>
                  <dd><span class='desc'>parameter z</span></dd> 
                </dl> 
              </div>
            </div>
          </div>
          <div class="section source"> 
            <span>[<a class="source_link" href="#">View source</a>]</span> 
            <div class="source_code" style="display: none"> 
              <table> 
                <tr> 
                  <td><pre class="lines">11</pre></td> 
                  <td><pre class="code"><span class="info file"># File '(stdin)', line 11</span> 
                  <span class='kw'>def</span> <span class='id m'>m</span>
                  <span class='lparen'>(</span><span class='op'>*</span>
                  <span class='id args'>args</span>
                  <span class='rparen'>)</span> <span class='kw'>end</span></pre></td> 
                </tr> 
              </table> 
            </div> 
          </div> 
        </div>
      eof
    end
  end
end