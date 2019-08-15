module HttpApiTools
  class SerializerLoader

    def self.preload

      file_paths = serializer_paths(Rails.root.join('app', 'serializers'))

      file_paths.each do |file_path|
        require file_path
      end

    end

    def self.serializer_paths(directory)
      directory = directory.to_s
      return [] unless Dir.exists?(directory)
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

