require 'spec_helper'
require 'http_api_tools/root_keyable'

module HttpApiTools

  describe RootKeyable do
    class AClassNamedHarry
      include RootKeyable
      def key
        root_key
      end

      def type
        root_type
      end
    end

    class BClassNamedJerry
      include RootKeyable
      def key
        root_key
      end

      def type
        root_type
      end
    end

    before do
      allow(clazz).to receive(:_serializes).and_return(serializes)
    end

    let(:keyable)    { clazz.new }
    let(:serializes) { double(name: clazz.to_s) }

    shared_examples 'a rootkeyable' do
      it 'has the correct root key' do
        expect(keyable.key).to eq(key)
      end

      it 'has the correct root type' do
        expect(keyable.type).to eq(type)
      end
    end

    context BClassNamedJerry do
      let(:clazz) { BClassNamedJerry }
      let(:type)  { "b_class_named_jerry" }
      let(:key)   { :b_class_named_jerries }

      it_behaves_like 'a rootkeyable'
    end

    context AClassNamedHarry do
      let(:clazz) { AClassNamedHarry }
      let(:type)  { "a_class_named_harry" }
      let(:key)   { :a_class_named_harries }

      it_behaves_like 'a rootkeyable'
    end

    context 'when inclusion is a chain' do
      module AModuleNamedSteve
        include RootKeyable
      end

      class AClassNamedJackie
        include AModuleNamedSteve
        def key
          root_key
        end

        def type
          root_type
        end
      end

      let(:clazz) { AClassNamedJackie }
      let(:type)  { "a_class_named_jacky" }
      let(:key)   { :a_class_named_jackies }

      it_behaves_like 'a rootkeyable'
    end

  end
end
