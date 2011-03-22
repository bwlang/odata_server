module OData
  module AbstractQuery
    module Segments
      class NavigationPropertySegment < EntityTypeAndKeyValuesSegment
        def self.parse!(query, str)
          return nil if query.segments.empty?
          return nil unless query.segments.last.respond_to?(:entity_type)
          entity_type = query.segments.last.entity_type
          return nil if entity_type.blank?

          schema_object_name, key_values, keys = extract_schema_object_name_and_key_values_and_keys(str)
          return nil if schema_object_name.blank?

          navigation_property = entity_type.navigation_properties.find { |np| np.name == schema_object_name }
          return nil if navigation_property.blank?

          if navigation_property.to_end.polymorphic?
            raise OData::AbstractQuery::Errors::AbstractQueryKeyValueException.new(query, key_values.keys.first, key_values.values.first) unless key_values.empty?
            raise OData::AbstractQuery::Errors::AbstractQueryKeyValueException.new(query, '$polymorphic#Key', keys.first) unless keys.empty?

            query.Segment(self, entity_type, navigation_property.to_end.return_type, navigation_property, {})
          else
            sanitized_key_values = sanitize_key_values_and_keys_for!(query, navigation_property.to_end.entity_type, key_values, keys)
            
            unless sanitized_key_values.empty?
              raise OData::AbstractQuery::Errors::AbstractQueryKeyValueException.new(query, sanitized_key_values.keys.first, sanitized_key_values.values.first) unless navigation_property.to_end.multiple?
            end

            query.Segment(self, entity_type, navigation_property.to_end.entity_type, navigation_property, sanitized_key_values)
          end
        end

        alias_method :to_entity_type, :entity_type

        attr_reader :navigation_property

        def initialize(query, from_entity_type, to_entity_type, navigation_property, key_values = {})
          @from_entity_type = from_entity_type
          @navigation_property = navigation_property

          super(query, to_entity_type, key_values)
        end

        def self.can_follow?(anOtherSegment)
          if anOtherSegment.is_a?(Class)
            anOtherSegment == CollectionSegment || anOtherSegment == NavigationPropertySegment
          else
            (anOtherSegment.is_a?(CollectionSegment) || anOtherSegment.is_a?(NavigationPropertySegment)) && !anOtherSegment.countable?
          end
        end      

        def countable?
          multiple? && super
        end

        def execute!(acc)
          [acc].flatten.compact.collect { |one|
            if key?
              @navigation_property.find_one(one, key_property_value)
            else
              @navigation_property.find_all(one, @key_values)
            end
          }.first
        end

        def multiple?
          @navigation_property.to_end.multiple?
        end

        def value
          if self.key_values.blank? || !multiple?
            @navigation_property.name
          elsif key?
            @navigation_property.name + '(' + key_property_value.to_s + ')'
          else
            @navigation_property.name + '(' + self.key_values.collect { |key, value| "#{key}=#{value}" }.join(',') + ')'
          end
        end
      end # NavigationPropertySegment
    end # Segments
  end # AbstractQuery
end # OData
