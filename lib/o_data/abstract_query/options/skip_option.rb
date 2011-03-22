module OData
  module AbstractQuery
    module Options
      class SkipOption < OData::AbstractQuery::Option
        def self.option_name
          '$skip'
        end

        def initialize(query, key, value = nil)
          super(query, key, value)
        end
        
        def self.applies_to?(query)
          return false if query.segments.empty?
          return false unless query.segments.last.respond_to?(:countable?)
          query.segments.last.countable?
        end

        def self.parse!(query, key, value = nil)
          return nil unless key == self.option_name
          
          query.Option(self, key, value.to_i)
        end

        def valid?
          return false if self.value.blank?
          self.value.to_i >= 0
        end
      end
    end
  end
end
