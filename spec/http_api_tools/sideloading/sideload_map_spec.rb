require 'spec_helper'
require 'http_api_tools/sideloading/sideload_map'

module HttpApiTools
  module Sideloading

    describe SideloadMap do

      let(:json) do
        {
          'meta' => {
            'root_key' => 'posts'
          },
          'posts' => [{
            'id' => 1,
            'title' => 'Post Title'
          }],
          'linked' => {
            'images' => [
              {'id' => 10, 'url' => '1.png' },
              {'id' => 11, 'url' => '2.png' }
            ],
            'comments' => [
              {'id' => 20, 'text' => 'Comment 1'}
            ]
          }
        }

      end

      let(:sideload_map) { SideloadMap.new(json, 'posts') }

      describe 'getting sideloaded json from the map' do

        it 'returns object at root key' do
          expect(sideload_map.get('post', 1)['id']).to eql 1
        end

        it 'retrieves by singular type' do
          expect(sideload_map.get('image', 10)['id']).to eql 10
        end

        it 'retrieves by plural type' do
          expect(sideload_map.get('images', 11)['id']).to eql 11
        end

        it 'retrieves with string type' do
          expect(sideload_map.get('comment', 20)['id']).to eql 20
        end

        it 'returns nil if object not present' do
          expect(sideload_map.get('foo', 100)).to be_nil
        end

      end

    end
  end
end