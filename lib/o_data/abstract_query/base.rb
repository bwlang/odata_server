module OData
  module AbstractQuery
    class Base
      attr_reader :schema
      attr_reader :segments, :options
      
      def initialize(schema, segments = [], options = [])
        @schema = schema
        
        @segments = segments
        @options = options
      end
      
      def inspect
        "#<< #{@schema.namespace.to_s}(#{self.to_uri.inspect}) >>"
      end
      
      def Segment(*args)
        segment_class = begin
          if args.first.is_a?(Symbol) || args.first.is_a?(String)
            "OData::AbstractQuery::Segments::#{args.shift.to_s}Segment".constantize
          else
            args.shift
          end
        end
        
        segment = segment_class.new(self, *args)
        
        @segments << segment
        segment
      end
      
      def Option(*args)
        option_class = begin
          if args.first.is_a?(Symbol) || args.first.is_a?(String)
            "OData::AbstractQuery::Options::#{args.shift.to_s}Option".constantize
          else
            args.shift
          end
        end
        
        option = option_class.new(self, *args)
        
        @options << option
        option
      end
      
      def resource_path
        @segments.collect(&:value).join('/')
      end
      
      def query_string
        @options.collect { |o| "#{o.key.to_s}=#{o.value.to_s}" }.join('&')
      end
      
      def to_uri
        [resource_path, query_string].reject(&:blank?).join('?')
      end
      
      def execute!
        _execute!
      end
      
      # def entity_type
      #   return nil if @segments.empty?
      #   return nil unless @segments.last.respond_to?(:entity_type)
      #   @segments.last.entity_type
      # end
      
      protected
      
      def _execute!
        _segments = [@segments].flatten.compact
        results = __execute!([], nil, _segments.shift, _segments)
        
        results = with_skip_and_top_options(with_orderby_option(results))
        
        results
      end
      
      def __execute!(seen, acc, head, rest)
        return acc if head.blank?
        raise Errors::InvalidSegmentContext.new(self, head) unless seen.empty? || head.can_follow?(seen.last)
        
        results = head.execute!(acc)
        raise Errors::ExecutionOfSegmentFailedValidation.new(self, head) unless head.valid?(results)

        seen << head
        __execute!(seen, results, rest.shift, rest)
      end
      
      private
      
      def with_orderby_option(results)
        orderby_option = @options.find { |o| o.option_name == Options::OrderbyOption.option_name }
        
        orderby = orderby_option.blank? ? nil : orderby_option.pairs
        
        if orderby && (entity_type = orderby_option.entity_type)
          results = entity_type.sort(results, orderby)
        else
          results
        end
      end
      
      def with_skip_and_top_options(results)
        skip_option = @options.find { |o| o.option_name == Options::SkipOption.option_name }
        top_option = @options.find { |o| o.option_name == Options::TopOption.option_name }
        
        skip = skip_option.blank? ? nil : skip_option.value.to_i
        top = top_option.blank? ? nil : top_option.value.to_i
        
        if skip && top
          results = results.slice(skip, top)
        elsif skip
          results = results.slice(skip..-1)
        elsif top
          results = results.slice(0, top)
        else
          results
        end
      end
    end
  end
  
  module AbstractSchema
    class Base
      def Query(*args)
        OData::AbstractQuery::Base.new(self, *args)
      end
    end
  end
end
