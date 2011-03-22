module OData
  module AbstractSchema
    class NavigationProperty < SchemaObject
      attr_reader :entity_type
      attr_accessor :association, :from_end, :to_end
      
      def initialize(schema, entity_type, name, association, options = {})
        super(schema, name)

        @entity_type = entity_type
        @association = association

        options.reverse_merge!(:source => true)

        if options[:source]
          @from_end = @association.from_end
          @to_end = @association.to_end
        else
          @to_end = @association.to_end
          @from_end = @association.from_end
        end
      end
      
      def return_type
        @to_end.return_type
      end
      
      def find_all(one, key_values = {})
        nil
      end
      
      def find_one(one, key_value = nil)
        nil
      end
    end
  end
end
