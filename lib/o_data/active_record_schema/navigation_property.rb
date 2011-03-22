module OData
  module ActiveRecordSchema
    class NavigationProperty < OData::AbstractSchema::NavigationProperty
      def self.name_for(reflection)
        reflection.name.to_s
      end
      
      def self.association_for(schema, reflection)
        schema.Association(reflection)
      end

      def initialize(schema, entity_type, reflection)
        super(schema, entity_type, self.class.name_for(reflection), self.class.association_for(schema, reflection), :source => true)
      end

      def method_name
        self.association.reflection.name.to_sym
      end
      
      def find_all(one, key_values = {})
        results = one.send(method_name)
        unless key_values.blank?
          if results.respond_to?(:find)
            results = results.find(:all, :conditions => self.entity_type.conditions_for_find(key_values)) 
          else
            # TODO: raise exception if key_values supplied for non-finder method
          end
        end
        results
      end
      
      def find_one(one, key_value = nil)
        results = one.send(method_name)
        unless key_value.blank?
          if results.respond_to?(:find)
            results = results.find(key_value)
          else
            # TODO: raise exception if key_value supplied for non-finder method
          end
        end
        results
      end
    end
  end
end
