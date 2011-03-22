module OData
  module AbstractQuery
    module Options
      class ExpandOption < OData::AbstractQuery::Option
        def self.option_name
          '$expand'
        end

        attr_reader :navigation_property_paths, :navigation_property_paths_str

        # TODO: remove navigation_property_paths_str
        def initialize(query, navigation_property_paths = {}, navigation_property_paths_str = nil)
          @navigation_property_paths = navigation_property_paths
          @navigation_property_paths_str = navigation_property_paths_str
          
          super(query, self.class.option_name)
        end
        
        def self.applies_to?(query)
          return false if query.segments.empty?
          (query.segments.last.is_a?(OData::AbstractQuery::Segments::CollectionSegment) || query.segments.last.is_a?(OData::AbstractQuery::Segments::NavigationPropertySegment))
        end

        def self.parse!(query, key, value = nil)
          return nil unless key == self.option_name
          
          if query.segments.last.respond_to?(:navigation_property)
            navigation_property = query.segments.last.navigation_property
            
            raise OData::AbstractQuery::Errors::InvalidOptionValue.new(query, self.option_name) if navigation_property.to_end.polymorphic?
          end
          
          if query.segments.last.respond_to?(:entity_type)
            entity_type = query.segments.last.entity_type
            
            navigation_property_paths = value.to_s.split(/\s*,\s*/).inject({}) { |acc, path| 
              segments = path.split('/')
              reflect_on_navigation_property_path(query, acc, entity_type, segments.shift, segments)
              acc
            }
            
            query.Option(self, navigation_property_paths, value.to_s)
          else
            raise OData::AbstractQuery::Errors::InvalidOptionContext.new(query, self.option_name) unless value.blank?
          end
        end

        def valid?
          # TODO: replace with validation
          true
        end
        
        def value
          "'" + @navigation_property_paths_str.gsub(/\s+/, '') + "'"
        end
        
        protected
        
        def self.reflect_on_navigation_property_path(query, acc, entity_type, head, rest)
          if head.blank?
            acc
          elsif entity_type.blank?
            raise OData::AbstractQuery::Errors::NavigationPropertyNotFound.new(nil, head)
          elsif navigation_property = entity_type.navigation_properties.find { |np| np.name == head }    
            acc[navigation_property] ||= {}
            
            if navigation_property.to_end.polymorphic?
              raise OData::AbstractQuery::Errors::InvalidOptionValue.new(query, head) unless rest.empty?
            else
              reflect_on_navigation_property_path(query, acc[navigation_property], navigation_property.to_end.entity_type, rest.shift, rest)
            end
            
            acc
          else
            raise OData::AbstractQuery::Errors::NavigationPropertyNotFound.new(nil, head)
          end
        end
      end
    end
  end
end
