module OData
  module AbstractQuery
    module Segments
      class PropertySegment < EntityTypeSegment
        attr_reader :property

        def self.parse!(query, str)
          return nil if query.segments.empty?
          return nil unless query.segments.last.respond_to?(:entity_type)
          entity_type = query.segments.last.entity_type
          return nil if entity_type.nil?
          property = entity_type.properties.find { |p| p.name == str }
          return nil if property.blank?

          query.Segment(self, entity_type, property)
        end

        def initialize(query, entity_type, property)
          @property = property

          super(query, entity_type, @property.name)
        end

        def self.can_follow?(anOtherSegment)
          if anOtherSegment.is_a?(Class)
            anOtherSegment == CollectionSegment || anOtherSegment == NavigationPropertySegment
          else
            (anOtherSegment.is_a?(CollectionSegment) || anOtherSegment.is_a?(NavigationPropertySegment)) && !anOtherSegment.countable?
          end
        end

        def countable?
          false
        end

        def execute!(acc)
          # [acc].flatten.compact.collect { |one|
          #   [one, @property.value_for(one)]
          # }
          { @property => @property.value_for([acc].flatten.compact.first) }
        end

        def valid?(results)
          # results.is_a?(Array)
          !results.blank?
        end
      end # PropertySegment
    end # Segments
  end # AbstractQuery
end # OData
