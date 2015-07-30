require 'spec_helper'
require 'http_api_tools/relation_includes'

module HttpApiTools
  describe RelationIncludes do

    context 'when constructed with no value' do
      let(:includes) { RelationIncludes.new }

      it 'is empty, not present and blank' do
        expect(includes).to be_empty
        expect(includes).to be_blank
        expect(includes).to_not be_present
      end
    end

    describe 'equality' do

      it 'works as expected' do
        one = [ :tags, { images: [:comments] }, { reviews: [:author] } ]
        two = [ :tags, { images: [:comments] }, { reviews: [:author] } ]
        expect(RelationIncludes.new(*one)).to eq RelationIncludes.new(*two)

        one = [ { reviews: [:author] }, :tags, { images: [:comments] } ]
        two = [ :tags, { images: [:comments] }, { reviews: [:author] } ]
        expect(RelationIncludes.new(*one)).to eq RelationIncludes.new(*two)

        one = [ :tags, { images: [:comments] }, { reviews: [:author] } ]
        two = [ :tags, { images: [:comments] }, :reviews ]
        expect(RelationIncludes.new(*one)).to_not eq RelationIncludes.new(*two)
      end
    end

    describe '.from_string' do

      let(:string)   { 'a,a.b,a.b.c,b,c' }
      let(:includes) { RelationIncludes.from_string(string) }

      it 'creates single level includes' do
        expect(includes).to include :b
        expect(includes).to include :c
      end

      it 'creates nested includes' do
        expect(includes).to include({ a: [{ b: [:c] }] })
      end

      it 'creates same structure when implicit parts of the path are removed' do
        simplified_params = 'a.b.c,b,c'
        simplified_includes =  RelationIncludes.from_string(simplified_params)
        expect(includes).to eq simplified_includes
      end

      context 'when a nil or empty string is provided' do

        it 'returns a new includes' do
          expect(RelationIncludes.from_string(nil)).to eq RelationIncludes.new
          expect(RelationIncludes.from_string('')).to eq RelationIncludes.new
        end
      end
    end

    describe "#to_s" do

      it "converts to dot-notation specified by the JSON API spec, sorted alphabetically" do
        includes = RelationIncludes.new(:reviews, { images: [{ comments: [:author] }] }, :hashtags)
        expect(includes.to_s).to eq 'hashtags,images,images.comments,images.comments.author,reviews'

        includes = RelationIncludes.new(:hashtags, { images: [{ comments: [:author, :rating] }] }, :reviews)
        expect(includes.to_s).to eq 'hashtags,images,images.comments,images.comments.author,images.comments.rating,reviews'
      end
    end

    describe '#&' do

      let(:relations) { [ :tags, { images: [:comments] }, { reviews: [:author] } ] }
      let(:includes)  { RelationIncludes.new(*relations) }

      let(:scenarios) do
        [
          {
            includes: [ { images: [:comments] } ],
            other:    [ { images: [:comments] } ],
            expected: [ { images: [:comments] } ]
          },
          {
            includes: [ { images: [:comments, :hashtags]} ],
            other:    [ { images: [:comments] } ],
            expected: [ { images: [:comments] } ]
          },
          {
            includes: [ { images: [:comments] } ],
            other:    [ { images: [:comments, :hashtags] } ],
            expected: [ { images: [:comments] } ]
          },
          {
            includes: [ :reviews, { images: [{ comments: [:author] }] }, :hashtags ],
            other:    [ :reviews, { images: [{ comments: [:author] }] }, :hashtags ],
            expected: [ :reviews, { images: [{ comments: [:author] }] }, :hashtags ]
          },
          {
            includes: [ :reviews, :hashtags, { images: [{ comments: [{ author: [:name] }, :foo, :bar] }] }],
            other:    [ :reviews, :hashtags, { images: [{ comments: [{ author: [:name] }, :foo] }] }],
            expected: [ :reviews, :hashtags, { images: [{ comments: [{ author: [:name] }, :foo] }] }]
          },
          {
            includes: [:main_image, :customer_ratings, { room_types: [{offers: [:inclusions, :promotion, :cancellation_policy, { charges: [:payable_at_property]}]}]}],
            other:    [:main_image, :customer_ratings, { room_types: [{offers: [:inclusions, :promotion, :cancellation_policy, { charges: [:payable_at_property]}]}]}],
            expected: [:main_image, :customer_ratings, { room_types: [{offers: [:inclusions, :promotion, :cancellation_policy, { charges: [:payable_at_property]}]}]}]
          },
          {
            includes: [ :reviews, { images: [{ comments: [:author] }] } ],
            other:    [ :reviews, { images: [ :comments ]} ],
            expected: [ :reviews, { images: [ :comments ]} ]
          },
          {
            includes: [ :reviews, { images: [ :comments ]} ],
            other:    [ :reviews, { images: [{ comments: [:author] }] } ],
            expected: [ :reviews, { images: [ :comments ]} ]
          },
          {
            includes: [ :reviews, { images: [{ comments: [:author] }] } ],
            other:    [ :reviews, :images ],
            expected: [ :reviews, :images ]
          },
          {
            includes: [ :reviews, {images: [{ comments: [:author] }] } ],
            other:    [ :reviews, :images, :hashtags ],
            expected: [ :reviews, :images ]
          }
        ]
      end

      [:customer_ratings, :main_image, {:room_types=>[{:offers=>[:cancellation_policy, {:charges=>[:payable_at_property]}, :inclusions, :promotion]}]}]

      it 'reuturns a new RelationIncludes as a deep intersection between two RelationIncludes' do
        # RelationIncludes.new(:customer_ratings, :main_image, {:room_types=>[{:offers=>[:cancellation_policy, {:charges=>[:payable_at_property]}, :inclusions, :promotion]}]}).to_s
        scenarios.each do |scenario|
          includes = scenario[:includes]
          other    = scenario[:other]
          expected = scenario[:expected]

          intersection = RelationIncludes.new(*includes) & RelationIncludes.new(*other)
          expect(intersection).to eq RelationIncludes.new(*expected)
        end
      end

    end

    describe "#includes_relation?" do

      let(:includes) { RelationIncludes.new(:a, { b: [:c] }) }

      it "includes correct relations when a symbol" do
        expect(includes.includes_relation?(:a)).to be_truthy
      end

      it "includes relations when key of object" do
        expect(includes.includes_relation?(:b)).to be_truthy
      end

      it "does not include unspecified relations" do
        expect(includes.includes_relation?(:x)).to be_falsey
      end

    end

    describe "#include" do

      let(:includes) { RelationIncludes.new(:a, { b: [:c] }) }

      it "includes new relations" do
        includes.include([:y, :z])
        expect(includes).to include :y
        expect(includes).to include :z
      end
    end

    describe "#find"  do

      let(:includes) { RelationIncludes.new(:a, { b: [:c] }) }

      it "finds include by key" do
        expect(includes.find(:b)).to eq({ b: [:c] })
      end
    end

    describe "#nested_includes_for"  do

      let(:includes) { RelationIncludes.new(:a, { b: [:c] }) }

      it "returns nested includes" do
        expect(includes.nested_includes_for(:b)).to eq([:c])
      end
    end

    describe "#for_query" do

      let(:includes) { RelationIncludes.new(:employer, { skills: [:person] }).for_query(HttpApiTools::Sideloading::PersonSerializer) }

      it "creates includes for included relationships and has_many relationships for fetching ids" do
        expect(includes.find(:employer)).to eq({ employer: [:employees] })
        expect(includes.find(:skills)).to eq({ skills: [{ person: [:skills] }] })
      end

    end

  end
end