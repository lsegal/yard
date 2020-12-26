# frozen_string_literal: true

# Load logger to fix autoload issue
::Logger

RSpec.describe YARD::Parser::RBS::RBSParser do
  describe '#parse' do
    def parse(contents)
      Registry.clear
      YARD.parse_string(contents, :rbs)
    end

    describe 'ChatApp example' do
      before(:all) do
        file = File.join(File.dirname(__FILE__), 'examples', 'chat_app.rbs')
        parse(File.read(file))
      end

      it 'handles ChatApp' do
        mod = YARD::Registry.at('ChatApp')
        expect(mod.type).to eq(:module)
      end
    end
  end
end
