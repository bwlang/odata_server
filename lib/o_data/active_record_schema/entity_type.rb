module OData
  module ActiveRecordSchema
    class EntityType < OData::AbstractSchema::EntityType      
      def self.name_for(active_record_or_str)
        name = active_record_or_str.is_a?(ActiveRecord::Base) ? active_record_or_str.name : active_record_or_str.to_s
        name.gsub('::', '')
      end
      
      def self.primary_key_for(active_record)
        active_record.primary_key
      end
      
      attr_reader :active_record
      
      def initialize(schema, active_record, options = {})
        super(schema, self.class.name_for(active_record))
        
        options.reverse_merge!(:reflect_on_associations => true)
        
        @active_record = active_record

        key_property_name = self.class.primary_key_for(@active_record).to_s
        
        @active_record.columns.each do |column_adapter|
          property = self.Property(column_adapter)
          
          if key_property_name == property.name
            self.key_property = property
          end
        end
        
        OData::AbstractSchema::Serializable.atom_element_names.each do |atom_element_name|
          o_data_active_record_method_name = :"o_data_atom_#{atom_element_name}"
          o_data_entity_type_property_name = :"atom_#{atom_element_name}_property"
          
          if @active_record.respond_to?(o_data_active_record_method_name)
            result = @active_record.send(o_data_active_record_method_name)
            next unless result.is_a?(Symbol)
            
            property = self.properties.find { |p| p.name == result.to_s }
            next if property.blank?
              
            self.send(:"#{o_data_entity_type_property_name}=", property)
          elsif !@active_record.instance_methods.include?(o_data_active_record_method_name.to_s) && @active_record.column_names.include?(atom_element_name.to_s)
            property = self.properties.find { |p| p.name == atom_element_name.to_s }
            next if property.blank?

            self.send(:"#{o_data_entity_type_property_name}=", property)
          end
        end
        
        if options[:reflect_on_associations]        
          @active_record.reflect_on_all_associations.each do |reflection|
            self.NavigationProperty(reflection)
          end
        end
      end

      def Property(*args)
        property = Property.new(self.schema, self, *args)
        self.properties << property
        property
      end

      def NavigationProperty(*args)
        navigation_property = NavigationProperty.new(self.schema, self, *args)
        self.navigation_properties << navigation_property
        navigation_property
      end

      def find_all(key_values = {})
        if @active_record.respond_to?(:with_permissions_to)
          @active_record.with_permissions_to(:read).find(:all, :conditions => conditions_for_find(key_values))
        else
          @active_record.find(:all, :conditions => conditions_for_find(key_values))
        end
      end
      
      def find_one(key_value)
        return nil if self.key_property.blank?
        if @active_record.respond_to?(:with_permissions_to)
          @active_record.with_permissions_to(:read).find(key_value)
        else
          @active_record.find(key_value)
        end
      end
      
      def conditions_for_find(key_values = {})
        self.class.conditions_for_find(self, key_values)
      end
      
      def self.conditions_for_find(entity_type, key_values = {})
        return "1=0" unless entity_type.is_a?(OData::ActiveRecordSchema::EntityType)
        return "1=1" if key_values.blank?
        
        key_values.collect { |pair|
          property_or_str, value = pair
          
          property = begin
            if property_or_str.is_a?(Property)
              property_or_str
            else
              property = entity_type.properties.find { |p| p.name == property_or_str.to_s }
              raise OData::AbstractQuery::Errors::PropertyNotFound.new(nil, property_or_str) if property.blank?
            end
          end
          
          [property, value]
        }.reject { |pair|
          pair.first.blank?
        }.inject({}) { |acc, pair|
          property, value = pair
          
          acc[property.column_adapter.name.to_sym] = value
          acc
        }
      end
      
      def self.href_for(one)
        one.class.name.pluralize + '(' + one.send(one.class.send(:primary_key)).to_s + ')'
      end
      
      def href_for(one)
        self.class.href_for(one)
      end
    end
  end
end
