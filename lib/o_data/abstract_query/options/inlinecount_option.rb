module OData
  module AbstractQuery
    module Options
      class InlinecountOption < EnumeratedOption
        def self.option_name
          '$inlinecount'
        end
        
        def self.valid_values
          %w{none allpages}
        end
        
        def self.applies_to?(query)
          return false if query.segments.empty?
          query.segments.last.is_a?(OData::AbstractQuery::Segments::CollectionSegment) || query.segments.last.is_a?(OData::AbstractQuery::Segments::NavigationPropertySegment)
        end
      end
    end
  end
end
