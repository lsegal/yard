require File.dirname(__FILE__) + '/spec_helper'

describe Template.template(:default, :class) do
  before do
    YARD.parse_string <<-eof
      private
      # Comments
      # @author Test
      # @version 1.0
      # @see A
      # @see http://example.com Example
      class A
      end
    eof
  end
  
  it "should render correctly" do
    html_equals(Registry.at('A').format(:format => :html), <<-'eof')
      <div class="docstring">Comments</div>
      <div class="tags">
        <div class="author">
          <h3>Author:</h3>
          <dl>
            <dt></dt>
            <dd><span class='desc'>Test</span></dd>
          </dl>
        </div>
        <div class="version">
          <h3>Version:</h3>
          <dl>
            <dt></dt>
            <dd><span class='desc'>1.0</span></dd>
          </dl>
        </div>
        <div class="see">
          <h3>See Also:</h3>
          <dl>
            <dt></dt>
            <dd>
              <span class='desc'>
                <tt>A</tt>,
                <tt><a href="http://example.com" title="Example">Example</a></tt>
              </span>
            </dd>
          </dl>
        </div>
      </div>
    eof
  end
end