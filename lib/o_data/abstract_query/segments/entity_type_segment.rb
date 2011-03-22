module OData
  module AbstractQuery
    module Segments
      class EntityTypeSegment < OData::AbstractQuery::Segment
        include OData::AbstractQuery::Countable

        attr_reader :entity_type

        def initialize(query, entity_type, value = nil)
          @entity_type = entity_type

          super(query, value || (@entity_type.is_a?(OData::AbstractSchema::EntityType) ? @entity_type.plural_name : @entity_type))
        end

        def self.can_follow?(anOtherSegment)
          false
        end

        def execute!(acc)
          return [] if @entity_type.blank?

          @entity_type.find_all
        end

        def valid?(results)
          countable? ? results.is_a?(Array) : !results.blank?
        end
      end # EntityTypeSegment
    end # Segments
  end # AbstractQuery
end # OData
