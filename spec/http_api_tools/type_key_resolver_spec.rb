require 'spec_helper'
require 'http_api_tools/type_key_resolver'

module HttpApiTools

  describe TypeKeyResolver do

    let(:resolver) { TypeKeyResolver.new }

    describe 'resolving class names' do

      it 'correctly resolves the type key multiple times' do
        expect(resolver.for_class(String)).to eq 'strings'
        expect(resolver.for_class(String)).to eq 'strings'
      end
    end

  end
end