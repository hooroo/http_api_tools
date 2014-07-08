module Hat
  module Model
    class HasManyArray < SimpleDelegator

      def initialize(array, owner, key)

        if array.kind_of?(HasManyArray)
          array = array.target_array
        end

        super(array)

        @owner = owner
        @key = key
      end

      [:<<, :push, :delete, :delete_at].each do |method_name|
        define_method(method_name) do |arg|
          target_array.send(method_name, arg)
          notify_owner
        end
      end

      [:clear, :shift].each do |method_name|
        define_method(method_name) do
          target_array.send(method_name)
          notify_owner
        end
      end

      protected

      def target_array
        __getobj__
      end

      private

      attr_reader :owner, :key

      def notify_owner
        owner.has_many_changed(self, key)
      end

    end
  end
end