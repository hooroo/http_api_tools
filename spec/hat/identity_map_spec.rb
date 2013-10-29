require 'spec_helper'
require 'hat/identity_map'

module Hat
  describe IdentityMap do

    let(:identity_map) { IdentityMap.new }
    let(:thing) { 'a thing' }

    describe "putting/getting items" do
      it "puts and revieves same object with string type key" do

        identity_map.put('thing', 1, thing)
        expect(identity_map.get('thing', 1)).to eql thing
      end

      it "puts and revieves same object with symbol type key" do
        identity_map.put(:thing, 1, thing)
        expect(identity_map.get(:thing, 1)).to eql thing
      end

      it "puts and revieves same object with mixed type key" do
        identity_map.put(:thing, 1, thing)
        expect(identity_map.get('thing', 1)).to eql thing
      end

    end
  end
  class IdentityMapThing ; end
end

