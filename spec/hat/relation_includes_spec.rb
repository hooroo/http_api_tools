require 'spec_helper'
require 'hat/relation_includes'

module Hat
  describe RelationIncludes do

    let(:relation_includes) { RelationIncludes.new([:a, {b: [:c]}]) }

    describe "#include?" do
      it "includes correct relations when a symbol" do
        expect(relation_includes.include?(:a)).to be_true
      end

      it "includes relations when key of object" do
        expect(relation_includes.include?(:b)).to be_true
      end

      it "does not include unspecified relations" do
        expect(relation_includes.include?(:x)).to be_false
      end

      it "can be splat as args" do
        collaborator = double('collaborator', splatter: nil)
        collaborator.should_receive(:splatter).with(:a, {b: [:c]})
        collaborator.splatter(*relation_includes)
      end
    end

    describe "#include" do
      it "includes new relations" do
        relation_includes.include([:y, :z])
        expect(relation_includes.include?(:y)).to be_true
        expect(relation_includes.include?(:z)).to be_true
      end
    end

    describe "#find"  do
      it "finds include by key" do
        expect(relation_includes.find(:b)).to eq({b: [:c]})
      end
    end

    describe "#nested_includes_for"  do
      it "returns nested includes" do
        expect(relation_includes.nested_includes_for(:b)).to eq([:c])
      end
    end

    describe 'from params' do
      let(:params) { {include: 'a,a.b,a.b.c,b,c'} }

      let(:includes) { RelationIncludes.from_params(params) }

      it 'creates single level includes' do
        expect(includes).to include :b
        expect(includes).to include :c
      end

      it 'creates nested includes' do
        expect(includes.find(:a)).to eq({a: [{b: [:c]}]})
      end

      it 'creates same structure when implicit parts of the path are removed' do
        simplified_params =  { include: 'a.b.c,b,c' }
        simplified_includes =  RelationIncludes.from_params(simplified_params)
        expect(includes.includes).to eql simplified_includes.includes
      end
    end

  end
end