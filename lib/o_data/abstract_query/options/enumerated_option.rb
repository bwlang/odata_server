module OData
  module AbstractQuery
    module Options
      class EnumeratedOption < OData::AbstractQuery::Option
        def self.valid_values
          %w{}
        end

        def valid_values
          self.class.valid_values
        end

        def initialize(query, key, value = nil)
          super(query, key, value)
        end
        
        # def self.applies_to?(query)
        #   false
        # end

        def self.parse!(query, key, value = nil)
          return nil unless key == self.option_name
          return nil if valid_values.empty?
          
          if value.blank?
            query.Option(self, key, valid_values.first)
          else
            query.Option(self, key, value)
          end
        end

        def valid?
          return false if self.value.blank? || self.valid_values.empty?
          self.valid_values.collect(&:to_s).include?(self.value.to_s)
        end
      end
    end
  end
end
