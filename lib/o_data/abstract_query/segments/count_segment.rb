module OData
  module AbstractQuery
    module Segments
      class CountSegment < OData::AbstractQuery::Segment
        def self.parse!(query, str)
          return nil unless str.to_s == segment_name

          query.Segment(self)
        end

        def self.segment_name
          "$count"
        end

        def initialize(query)
          super(query, self.class.segment_name)
        end

        def self.can_follow?(anOtherSegment)
          if anOtherSegment.is_a?(Class)
            anOtherSegment == CollectionSegment || anOtherSegment == NavigationPropertySegment
          else
            (anOtherSegment.is_a?(CollectionSegment) || anOtherSegment.is_a?(NavigationPropertySegment)) && anOtherSegment.countable?
          end
        end

        def execute!(acc)
          return acc.length if acc.respond_to?(:length)
          1
        end

        def valid?(results)
          results.is_a?(Fixnum)
        end
      end # CountSegment
    end # Segments
  end # AbstractQuery
end # OData
