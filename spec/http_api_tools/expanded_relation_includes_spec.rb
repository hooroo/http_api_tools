require 'spec_helper'
require 'http_api_tools/expanded_relation_includes'

module HttpApiTools
  describe ExpandedRelationIncludes do

    describe "#to_a" do

      let(:expanded_includes) { ExpandedRelationIncludes.new(includes, HttpApiTools::Sideloading::PersonSerializer) }

      context 'with single-level includes' do

        let(:includes) { [:employer, :skills] }

        it "expands includes to include has_many relationships defined by serializers but not in original includes" do
          expect(expanded_includes.to_a).to eq([:hidden_talents, { employer: [:employees] }, :skills])
        end
      end

      context 'with multi-level includes' do

        let(:includes) { [:employer, { skills: [:person] }] }

        it "expands includes to include has_many relationships defined by serializers but not in original includes" do
          expect(expanded_includes.to_a).to eq([:hidden_talents, { employer: [:employees] }, { skills: [{ person: [:skills, :hidden_talents] }] }])
        end
      end

    end
  end
end