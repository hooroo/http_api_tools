#Adds methods that help a client to behave as if it's dealing with an ActiveModel object.
#Principle of least surprise here - if someone is working in Rails and using a model it should
#feel normal and they should be able to do all the things the'd do with an active model object except
#interact with the database.
module Hat
  module Model
    module ActsLikeActiveModel

      def to_param
        if self.respond_to?(:id)
          self.id
        end
      end
    end
  end
end