module OData
  module AbstractQuery
    class BasicOption
      def self.option_name(option)
        nil
      end
      
      def option_name
        @key
      end
      
      attr_reader :query, :key, :value
      
      def initialize(query, key, value = nil)
        @query = query
        @key = key
        @value = value
      end
      
      def inspect
        "#<< #{@query.schema.namespace.to_s}(#{@key.to_s}=#{@value.to_s}) >>"
      end
    end
    
    class Option < BasicOption
      def self.option_name
        name.to_s.demodulize.sub(/Option$/, '')
      end
      
      def option_name
        self.class.option_name
      end
      
      def initialize(query, key, value = nil)
        super(query, key, value)
        
        raise Errors::InvalidOptionContext.new(self.query, self) unless applies_to?
        raise Errors::InvalidOptionValue.new(self.query, self) unless valid?
      end
      
      def self.applies_to?(query)
        false
      end
      
      def self.parse!(query, key, value = nil)
        nil
      end
      
      def applies_to?
        self.class.applies_to?(self.query)
      end
      
      def valid?
        true
      end
    end
  end
end
