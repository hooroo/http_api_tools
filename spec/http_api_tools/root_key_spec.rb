require 'spec_helper'
require 'http_api_tools/json_serializer_dsl'

module HttpApiTools

  describe 'RootKey' do
    class TestSerializer
      include HttpApiTools::Nesting::JsonSerializer

      serializes(String, group: :foo)
    end

    class TestTwoSerializer
      include HttpApiTools::Nesting::JsonSerializer

      serializes(Hash, group: :foo)
    end

    let(:serialized) { serializer.new(serializable).as_json }

    context TestSerializer do
      let(:serializable) { 'the string' }
      let(:serializer)   { TestSerializer }

      it 'has the correct root key' do
        expect(serialized).to include(:strings)
      end
    end

    context TestTwoSerializer do
      let(:serializable) { {} }
      let(:serializer)   { TestTwoSerializer }

      it 'has the correct root key' do
        expect(serialized).to include(:hashes)
      end
    end

  end
end
