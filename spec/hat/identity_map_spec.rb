require 'spec_helper'
require 'hat/identity_map'

module Hat
  describe IdentityMap do

    let(:identity_map) { IdentityMap.new }

    describe "putting/getting items" do
      it "puts and revieves same object" do
        thing = IdentityMapThing.new
        identity_map.put(IdentityMapThing, 1, thing)
        expect(identity_map.get(IdentityMapThing, 1)).to eql thing
      end
    end
  end
  class IdentityMapThing ; end
end

