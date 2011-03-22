module OData
  module AbstractQuery
    module Segments
      class ValueSegment < OData::AbstractQuery::Segment
        def self.parse!(query, str)
          return nil unless str.to_s == segment_name

          query.Segment(self)
        end

        def self.segment_name
          "$value"
        end

        def initialize(query)
          super(query, self.class.segment_name)
        end

        def self.can_follow?(anOtherSegment)
          if anOtherSegment.is_a?(Class)
            anOtherSegment == PropertySegment
          else
            anOtherSegment.is_a?(PropertySegment)
          end
        end

        def execute!(acc)
          # acc
          acc.values.first
        end

        def valid?(results)
          # # results.is_a?(Array)
          # !results.blank?
          true
        end
      end # ValueSegment
    end # Segments
  end # AbstractQuery
end # OData
