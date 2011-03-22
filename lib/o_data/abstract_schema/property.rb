module OData
  module AbstractSchema
    class Property < SchemaObject
      cattr_reader :edm_null
      @@edm_null = 'Edm.Null'.freeze
      
      attr_reader :entity_type
      attr_accessor :return_type, :nullable

      def initialize(schema, entity_type, name, return_type = @@edm_null, nullable = true)
        super(schema, name)

        @entity_type = entity_type
        @return_type = return_type
        @nullable = nullable
      end

      def nullable?
        !!@nullable
      end

      def value_for(one)
        nil
      end
      
      def qualified_name
        @entity_type.qualified_name.to_s + '#' + self.name
      end
      
      def inspect
        "#<< {qualified_name.to_s}(return_type: #{@return_type.to_s}, nullable: #{nullable?}) >>"
      end
    end
  end
end
