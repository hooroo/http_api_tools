module HttpApiTools
  class SerializerLoader

    def self.preload

      file_names = serializer_paths(Rails.root.join('app', 'serializers'))

      file_names.each do |file_name|
        require file_name
      end

    end

    def self.serializer_paths(directory)
      directory = directory.to_s
      file_names = Dir.entries(directory).select { |file_name| file_name.end_with?('serializer.rb') }

      relevant_dir_path = directory.split('app/serializers/')[1] || ""
      full_paths = file_names.map {|file_name| relevant_dir_path + file_name }

      Dir.glob(directory + "/*/").each do |sub_directory|
        Array(full_paths).concat(Array(serializer_paths(sub_directory)))
      end

      full_paths
    end

  end
end

