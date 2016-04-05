require 'spec_helper'
require 'http_api_tools/json_serializer_dsl'

module HttpApiTools

  describe 'RootKey' do
    class RootKeyTestSerializer
      include HttpApiTools::Nesting::JsonSerializer

      serializes(String, group: :foo)
    end

    class RootKeyTestTwoSerializer
      include HttpApiTools::Nesting::JsonSerializer

      serializes(Hash, group: :foo)
    end

    let(:serialized) { serializer.new(serializable).as_json }

    context RootKeyTestSerializer do
      let(:serializable) { 'the string' }
      let(:serializer)   { RootKeyTestSerializer }

      it 'has the correct root key' do
        expect(serialized).to include(:strings)
      end
    end

    context RootKeyTestTwoSerializer do
      let(:serializable) { {} }
      let(:serializer)   { RootKeyTestTwoSerializer }

      it 'has the correct root key' do
        expect(serialized).to include(:hashes)
      end
    end

  end
end
