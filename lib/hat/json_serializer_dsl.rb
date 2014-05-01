module Hat
  module JsonSerializerDsl

      def has_ones
        self._relationships[:has_ones]
      end

      def has_manys
        self._relationships[:has_manys]
      end

      def attributes(*args)
        self._attributes = args
      end

      def has_one(has_one)
        self.has_ones << has_one
      end

      def has_many(has_many)
        self.has_manys << has_many
      end

      def includable(*includes)
        self._includable = RelationIncludes.new(*includes)
      end

    end
end