module OData
  module AbstractSchema
    class EntityType < SchemaObject
      attr_accessor :properties

      attr_accessor :navigation_properties

      def initialize(schema, name)
        super(schema, name)

        @properties = []
        @key_property = nil

        @navigation_properties = []
      end
      
      attr_reader :key_property

      def key_property=(property)
        return nil unless property.is_a?(Property)
        return nil unless @properties.include?(property)
        @key_property = property
      end

      def Property(*args)
        property = Property.new(self.schema, self, *args)
        @properties << property
        property
      end

      def NavigationProperty(*args)
        navigation_property = NavigationProperty.new(self.schema, self, *args)
        @navigation_properties << navigation_property
        navigation_property
      end

      def find_all(key_values = {})
        []
      end
      
      def find_one(key_value)
        return nil if @key_property.blank?
        find_all(@key_property => key_value).first
      end
      
      def exists?(key_value)
        !!find_one(key_value)
      end
      
      def href_for(one)
        collection_name + '(' + primary_key_for(one) + ')'
      end

      def primary_key_for(one)
        return nil if @key_property.blank?
        @key_property.value_for(one)
      end
      
      def inspect
        "#<< #{qualified_name.to_s}(#{[@properties, @navigation_properties].flatten.collect { |p| "#{p.name.to_s}: #{p.return_type.to_s}" }.join(', ')}) >>"
      end
    end
  end
end
