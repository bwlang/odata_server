module OData
  module AbstractQuery
    class Segment
      attr_reader :query, :value
      
      def self.parse!(query, str)
        nil
      end
      
      def self.segment_name
        name.to_s.demodulize.sub(/Segment$/, '')
      end
      
      def initialize(query, value)
        @query = query
        @value = value
        
        raise Errors::InvalidSegmentContext.new(@query, self) unless can_follow?(@query.segments.last)
      end
      
      def self.can_follow?(anOtherSegment)
        # self (Segment class) can_follow? anOtherSegment (instance of Segment class)
        false
      end
      
      def can_follow?(anOtherSegment)
        self.class.can_follow?(anOtherSegment)
      end
      
      def execute!(acc)
        acc
      end
      
      def inspect
        "#<< #{@query.schema.namespace.to_s}(#{self.class.segment_name}: #{self.value.inspect}) >>"
      end
      
      def valid?(results)
        !results.blank?
      end
    end
  end
end
