require 'spec_helper'
require 'hat/sideload_map'

module Hat

  describe SideloadMap do

    let(:json) do
      {
        'meta' => {

        },
        'post' => {
          'id' => 1,
          'title' => 'Post Title'
        },
        'images' => [
          {'id' => 10, 'url' => '1.png' },
          {'id' => 11, 'url' => '2.png' }
        ],
        'comments' => [
          {'id' => 20, 'text' => 'Comment 1'}
        ]
      }

    end

    let(:sideload_map) { SideloadMap.new(json, 'post') }

    describe 'getting sideloaded json from the map' do

      it 'returns object at root key' do
        expect(sideload_map.get('post', 1)['id']).to eql 1
      end

      it 'returns correctly by singular type' do
        expect(sideload_map.get('image', 10)['id']).to eql 10
      end

      it 'returns correctly by plural type' do
        expect(sideload_map.get('images', 11)['id']).to eql 11
      end

      it 'returns correctly with string type' do
        expect(sideload_map.get('comment', 20)['id']).to eql 20
      end

      it 'returns nil if object not present' do
        expect(sideload_map.get('foo', 100)).to be_nil
      end

    end

  end
end