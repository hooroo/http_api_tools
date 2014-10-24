require 'spec_helper'
require 'http_api_tools/model/transformers/registry'


module HttpApiTools
  module Model
    module Transformers

      describe Registry do

        let(:registry) { Registry.instance }

        describe 'registering and retrieving a transformer' do
          it 'adds to the registry' do
            registry.register(:foo, Object)
            expect(registry.get(:foo)).to eq Object
          end

          it 'raises an exception if a transformer is registered more than once' do
            registry.register(:xyz, Object)
            lambda { registry.register(:xyz, Object) }.should raise_error
          end
        end

        context 'with a registered transformer' do

          it 'transforms a raw value with the transformer' do
            date_string = '2000-10-10'
            date_result = Date.today
            registry.get(:date_time).should_receive(:from_raw).with(date_string).and_return(date_result)
            expect(registry.from_raw(:date_time, date_string)).to eq date_result

          end

        end

        context 'without a registered transformer' do
          it 'passes through a raw value' do
            raw_bar = 'bar'
            expect(registry.get(:bar)).to be_nil
            expect(registry.from_raw(:bar, raw_bar)).to eq raw_bar
          end
        end

        describe 'pre-registered transformers' do
          it 'has date_time transformer registered' do
            expect(registry.get(:date_time)).to eq DateTimeTransformer
          end
        end
      end
    end
  end
end