require 'spec_helper'
require 'hat/expanded_relation_includes'

module Hat
  describe ExpandedRelationIncludes do

    describe "#to_a" do

      let(:expanded_includes) { ExpandedRelationIncludes.new([:employer, { skills: [:person] }], Person) }

      it "expands includes to include has_many relationships defined by serializers but not in original includes" do
        expect(expanded_includes.to_a).to eq([{ employer: [:employees] }, { skills: [{ person: [:skills] }] }])
      end

    end

  end
end