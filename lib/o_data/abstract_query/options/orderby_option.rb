module OData
  module AbstractQuery
    module Options
      class OrderbyOption < OData::AbstractQuery::Option
        def self.option_name
          '$orderby'
        end

        attr_reader :pairs

        def initialize(query, pairs = [])
          @pairs = pairs
          
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
          
          raise OData::AbstractQuery::Errors::InvalidOptionContext.new(query, self) unless query.segments.last.respond_to?(:countable?) && query.segments.last.countable?
          
          if query.segments.last.respond_to?(:entity_type)
            entity_type = query.segments.last.entity_type
            
            pairs = value.to_s.split(/\s*,\s*/).collect { |path|
              if md = path.match(/^([A-Za-z_]+(?:\/[A-Za-z_]+)*)(?:\s+(asc|desc))?$/)
                property_name = md[1]
                order = md[2].blank? ? :asc : md[2].to_sym

                property = entity_type.properties.find { |p| p.name == property_name }
                raise OData::AbstractQuery::Errors::PropertyNotFound.new(query, property_name) if property.blank?

                [property, order]
              else
                raise OData::AbstractQuery::Errors::PropertyNotFound.new(query, path)
              end
            }
            
            query.Option(self, pairs.empty? ? [[entity_type.key_property, :asc]] : pairs)
          else
            raise OData::AbstractQuery::Errors::InvalidOptionContext.new(query, self.option_name) unless value.blank?
          end
        end
        
        def entity_type
          return nil if self.query.segments.empty?
          return nil unless self.query.segments.last.respond_to?(:entity_type)
          @entity_type ||= self.query.segments.last.entity_type
        end

        def valid?
          entity_type = self.entity_type
          return false if entity_type.blank?
          
          @pairs.is_a?(Array) && @pairs.all? { |pair|
            property, value = pair
            
            property.is_a?(OData::AbstractSchema::Property) && !!entity_type.properties.find { |p| p.name == property.name }
          }
        end
        
        def value
          "'" + @pairs.collect { |p| "#{p.first.name} #{p.last}" }.join(',') + "'"
        end
      end
    end
  end
end
