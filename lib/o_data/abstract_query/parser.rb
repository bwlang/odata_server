module OData
  module AbstractQuery
    class Parser
      cattr_reader :reserved_option_names
      @@reserved_option_names = %w{orderby expand select top skip filter format inlinecount}.freeze
      
      attr_reader :schema
      
      def initialize(schema)
        @schema = schema
      end
      
      def parse!(uri)
        return nil if uri.blank?
        
        query = @schema.Query
        
        resource_path, query_string = uri.split('?', 2)
        
        unless resource_path.blank?
          resource_path_components = resource_path.split('/')
          resource_path_components.each_index do |i|
            resource_path_component = resource_path_components[i]
            segment = _parse_segment!(query, resource_path_component)
          end
        end
        
        unless query_string.blank?
          query_string_components = query_string.split('&')
          query_string_components.each_index do |i|
            query_string_component = query_string_components[i]
            option = _parse_option!(query, query_string_component)
          end
        end
        
        query
      end
      
      protected
      
      def _parse_segment!(query, resource_path_component)
        Object.subclasses_of(Segment).each do |segment_class|
          if segment_class.can_follow?(query.segments.last)
            if segment = segment_class.parse!(query, resource_path_component)
              return segment
            end
          end
        end
        
        raise Errors::ParseQuerySegmentException.new(query, resource_path_component)
      end
      
      def _parse_option!(query, query_string_component)
        key, value = query_string_component.split('=', 2)
        
        if md = key.match(/^\$(.*?)$/)
          raise Errors::InvalidReservedOptionName.new(query, key, value) unless @@reserved_option_names.include?(md[1])
        end
        
        if md = value.match(/^'\s*([^']+)\s*'$/)
          value = md[1]
        end
        
        Object.subclasses_of(Option).each do |option_class|
          if option_class.applies_to?(query)
            if option = option_class.parse!(query, key, value)
              return option
            end
          end
        end
        
        # basic (or "custom") option
        query.Option(BasicOption, key, value)
      end
    end # Parser
  end # AbstractQuery
end # OData
