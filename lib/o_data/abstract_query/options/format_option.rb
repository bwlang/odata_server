module OData
  module AbstractQuery
    module Options
      class FormatOption < EnumeratedOption
        def self.option_name
          '$format'
        end
        
        def self.valid_values
          %w{atom json}
        end
        
        def self.applies_to?(query)
          true
        end
      end
    end
  end
end
