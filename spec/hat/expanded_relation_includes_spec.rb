require 'spec_helper'
require 'hat/expanded_relation_includes'

module Hat
  describe ExpandedRelationIncludes do

    describe "#to_a" do

      let(:serializer) { Hat::Sideloading::PersonSerializer.new(Person.new) }
      let(:expanded_includes) { ExpandedRelationIncludes.new(includes, serializer) }

      context 'with single-level includes' do

        let(:includes) { [:employer, :skills] }

        it "expands includes to include has_many relationships defined by serializers but not in original includes" do
          expect(expanded_includes.to_a).to eq([{ employer: [:employees] }, :skills])
        end
      end

      context 'with multi-level includes' do

        let(:includes) { [:employer, { skills: [:person] }] }

        it "expands includes to include has_many relationships defined by serializers but not in original includes" do
          expect(expanded_includes.to_a).to eq([{ employer: [:employees] }, { skills: [{ person: [:skills] }] }])
        end
      end

    end
  end
end