module OData
  module AbstractQuery
    module Errors
      class AbstractQueryException < OData::ODataException
        attr_reader :query
        
        def initialize(query)
          @query = query
        end
        
        def to_s
          "An unknown error has occured."
        end
      end
      
      class ParseQuerySegmentException < AbstractQueryException
        attr_reader :str
        
        def initialize(query, str)
          super(query)
          @str = str
        end
        
        def to_s
          "Resource not found for the segment '#{@str.to_s}'."
        end
      end
      
      class EntityTypeNotFound < ParseQuerySegmentException
        def to_s
          "EntityType not found for the segment '#{self.str.to_s}'"
        end
      end
      
      class PropertyNotFound < ParseQuerySegmentException
        def to_s
          "Property not found for the segment '#{self.str.to_s}'"
        end
      end
      
      class NavigationPropertyNotFound < ParseQuerySegmentException
        def to_s
          "NavigationProperty not found for the segment '#{self.str.to_s}'"
        end
      end
      
      class AbstractQuerySegmentException < AbstractQueryException
        attr_reader :segment
        
        def initialize(query, segment)
          super(query)
          
          @segment = segment
        end
      end
      
      class ExecutionOfSegmentFailedValidation < AbstractQuerySegmentException
        def to_s
          "Execution of the segment '#{@segment.value}' did not return a valid result."
        end
      end
      
      class InvalidSegmentContext < AbstractQuerySegmentException
        def to_s
          "Invalid context for the segment '#{@segment.value}'."
        end
      end
      
      class AbstractQueryKeyValueException < AbstractQueryException
        attr_reader :key, :value
        
        def initialize(query, key, value)
          super(query)
          
          @key = key
          @value = value
        end
        
        def to_s
          "An unknown error has occured for the query option '#{@key.to_s}'."
        end
      end
      
      class InvalidReservedOptionName < AbstractQueryKeyValueException
        def to_s
          "The query parameter '#{self.key.to_s}' begins with a system-reserved '$' character but is not recognized."
        end
      end
      
      class AbstractQueryOptionException < AbstractQueryException
        attr_reader :option
        
        def initialize(query, option)
          super(query)
          
          @option = option
        end
        
        def to_s
          "Invalid '#{@option.option_name.to_s}' query option."
        end
      end
      
      class InvalidOptionContext < AbstractQueryOptionException
        def to_s
          "Invalid context for the query option '#{self.option.option_name.to_s}'."
        end
      end
      
      class InvalidOptionValue < AbstractQueryOptionException
        def to_s
          "Invalid value for '#{self.option.option_name.to_s}' query option#{" - the only acceptable values are #{self.option.valid_values.collect { |v| v.to_s.inspect }.to_sentence}" if self.option.respond_to?(:valid_values)}."
        end
      end
    end
  end
end
