require 'spec_helper'
require 'http_api_tools/json_serializer_dsl'

module HttpApiTools
  describe JsonSerializerDsl do


    describe 'serializes' do
      it 'sets serializable class' do
        expect(TestSerializer.serializable_type).to eq(String)
      end
    end

    describe 'serializer_group' do
      it 'sets serializer group' do
        expect(TestSerializer.serializer_group).to eq(:foo)
      end
    end


    describe 'attributes' do
      it 'sets attributes' do
        expect(TestSerializer._attributes).to include(:a, :b, :c, :d)
      end
    end

    describe 'has_one' do
      it 'sets has_one' do
        expect(TestSerializer.has_ones).to include(:has_one_a, :has_one_b)
      end
    end

    describe 'has_many' do
      it 'sets has_many' do
        expect(TestSerializer.has_manys).to include(:has_many_a, :has_many_b)
      end
    end

    describe 'exclude_when' do
      it 'sets exclude_whens' do
        expect(TestSerializer._exclude_whens[:d]).to eq(:exclude_d?)
      end

      it "doesn't set when attribute not configured" do
        expect(TestSerializer._exclude_whens).to_not have_key(:a)
        expect(TestSerializer._exclude_whens).to_not have_key(:c)
      end
    end

    describe 'includable' do
      it 'sets includables' do
        expect(TestSerializer._includable).to eq(RelationIncludes.new(:a, :b))
      end
    end


    class TestSerializer

      include HttpApiTools::Nesting::JsonSerializer

      # JsonSerializerDsl.apply_to(self)

      serializes(String, group: :foo)

      attributes :a, :b
      attribute :c
      attribute :d, exclude_when: :exclude_d?

      has_one :has_one_a
      has_one :has_one_b

      has_many :has_many_a
      has_many :has_many_b

      includable(:a, :b)

    end

  end
end