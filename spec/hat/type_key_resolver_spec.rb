require 'spec_helper'
require 'hat/type_key_resolver'

module Hat

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