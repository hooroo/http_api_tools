module HttpApiTools
  class SerializerLoader

    def load_serializers

      file_names = Dir.entries(Rails.root.join('app', 'serializers')).select { |file_name| file_name.end_with?('serializer.rb') }.reverse

      file_names.each do |file_name|
        require file_name
      end

    rescue StandardError => e

      #no serializers directory found to load

    end

  end
end