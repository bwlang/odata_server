module OData
  module AbstractQuery
    module Segments
      class LinksSegment < OData::AbstractQuery::Segment
        include OData::AbstractQuery::Countable

        def self.parse!(query, str)
          return nil unless str.to_s == segment_name

          query.Segment(self)
        end

        def self.segment_name
          "$links"
        end
        
        def self.countable?
          true
        end

        def initialize(query)
          super(query, self.class.segment_name)
        end

        def self.can_follow?(anOtherSegment)
          if anOtherSegment.is_a?(Class)
            anOtherSegment == CollectionSegment || anOtherSegment == NavigationPropertySegment
          else
            (anOtherSegment.is_a?(CollectionSegment) || anOtherSegment.is_a?(NavigationPropertySegment)) # && anOtherSegment.countable?
          end
        end

        def execute!(acc)
          [acc].flatten.compact.collect { |one|
            if entity_type = self.query.schema.entity_types.find { |et| et.name == one.class.name }
              [one, entity_type.plural_name + '(' + entity_type.primary_key_for(one).to_s + ')']
            else
              [one, nil]
            end
          }
        end

        def valid?(results)
          results.all? { |pair| !pair[1].blank? }
        end
      end # LinksSegment
    end # Segments
  end # AbstractQuery
end # OData
