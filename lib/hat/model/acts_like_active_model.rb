module Hat
  module Model
    module ActsLikeActiveModel

      def to_param
        if self.respond_to(:id)
          self.id
        end
      end
    end
  end
end