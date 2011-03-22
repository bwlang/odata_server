module OData
  module AbstractQuery
    module Segments
      class EntityTypeAndKeyValuesSegment < EntityTypeSegment
        def self.remove_quotes(str)
          str.to_s.sub(/^\'(.*?)\'$/, '\1')
        end

        def self.extract_schema_object_name_and_key_values_and_keys(str)
          if md1 = str.to_s.match(/^([^\(]+)(?:\(([^\)]+)\)|\(\s*\))?$/)
            schema_object_name = md1[1]
            key_values = {}
            keys = []

            if key_values_string = md1[2]
              key_values_string.split(/\s*,\s*/).each do |key_value_pair|
                key, value = key_value_pair.split('=', 2)

                if value
                  key_values[key.to_sym] = remove_quotes(value)
                else
                  keys << remove_quotes(key)
                end
              end
            end

            [schema_object_name, key_values, keys]
          else
            nil
          end
        end

        def self.sanitize_key_values_and_keys_for!(query, entity_type, key_values = {}, keys = [])
          key_property_name = entity_type.key_property.name

          sanitized_key_values = key_values.inject({}) { |acc, key_value_pair|
            key, value = key_value_pair

            property = entity_type.properties.find { |p| p.name == key.to_s }
            raise OData::AbstractQuery::Errors::PropertyNotFound.new(query, key) if property.blank?
            
            raise OData::AbstractQuery::Errors::AbstractQueryKeyValueException.new(query, key, value) unless acc[key.to_sym].blank?

            acc[property.name.to_sym] = value
            acc
          }

          keys.inject(sanitized_key_values) { |acc, key_value| 
            raise OData::AbstractQuery::Errors::AbstractQueryKeyValueException.new(query, key_property_name, key_value) unless acc[key_property_name.to_sym].blank?
            
            acc[key_property_name.to_sym] = key_value
            acc
          }
        end

        attr_reader :key_values

        def initialize(query, entity_type, key_values = {})
          @key_values = key_values

          super(query, entity_type)
        end

        def countable?
          !key?
        end

        def execute!(acc)
          return [] if self.entity_type.blank?

          if key?
            self.entity_type.find_one(key_property_value)
          else
            self.entity_type.find_all(@key_values)
          end
        end

        def key?
          !self.entity_type.blank? && self.class.key?(self.entity_type, @key_values)
        end

        def key_property_value
          return nil if self.entity_type.blank?

          self.class.key_property_value_for(self.entity_type, @key_values)
        end

        def value
          if @key_values.blank?
            super
          elsif key?
            super + '(' + key_property_value.to_s + ')'
          else
            super + '(' + @key_values.collect { |key, value| "#{key}=#{value}" }.join(',') + ')'
          end
        end

        def self.key?(entity_type, key_values = {})
          !!key_property_value_for(entity_type, key_values)
        end

        def self.key_property_value_for(entity_type, key_values = {})
          return nil if entity_type.blank?

          return nil if key_values.blank?
          return nil unless key_values.size == 1

          key_property = entity_type.key_property
          return nil if key_property.blank?

          key_values[key_property.name.to_sym]
        end
      end # EntityTypeAndKeyValuesSegment
    end # Segments
  end # AbstractQuery
end # OData
