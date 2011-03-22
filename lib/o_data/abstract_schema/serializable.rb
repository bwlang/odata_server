module OData
  module AbstractSchema
    module Serializable
      def self.atom_element_names
        %w{title summary updated_at}
      end
      
      module SchemaInstanceMethods
        def atom_title_for(one)
          entity_type = find_entity_type(:active_record => one.class)
          return nil if entity_type.blank?
          
          entity_type.atom_title_for(one)
        end
        
        def atom_summary_for(one)
          entity_type = find_entity_type(:active_record => one.class)
          return nil if entity_type.blank?
          
          entity_type.atom_summary_for(one)
        end
        
        def atom_updated_at_for(one)
          entity_type = find_entity_type(:active_record => one.class)
          return nil if entity_type.blank?
          
          entity_type.atom_updated_at_for(one)
        end
      end
      
      module EntityTypeInstanceMethods
        def self.included(base)
          base.instance_eval do
            attr_reader *OData::AbstractSchema::Serializable.atom_element_names.collect { |atom_element_name| :"atom_#{atom_element_name}_property" }
          end
        end
        
        def atom_title_for(one)
          return href_for(one) if self.atom_title_property.blank?
          self.atom_title_property.value_for(one)
        end
        
        def atom_summary_for(one)
          return nil if self.atom_summary_property.blank?
          self.atom_summary_property.value_for(one)
        end
        
        def atom_updated_at_for(one)
          return nil if self.atom_updated_at_property.blank?
          self.atom_updated_at_property.value_for(one)
        end
        
        def atom_title_property=(property)
          return nil unless property.is_a?(Property)
          return nil unless property.return_type.to_s == 'Edm.String'
          return nil unless self.properties.find { |p| p.name == property.name }
          @atom_title_property = property
        end
        
        def atom_summary_property=(property)
          return nil unless property.is_a?(Property)
          return nil unless property.return_type.to_s == 'Edm.String'
          return nil unless self.properties.find { |p| p.name == property.name }
          @atom_summary_property = property
        end
        
        def atom_updated_at_property=(property)
          return nil unless property.is_a?(Property)
          return nil unless %w{Edm.Date Edm.DateTime Edm.Time}.include?(property.return_type.to_s)
          return nil unless self.properties.find { |p| p.name == property.name }
          @atom_updated_at_property = property
        end
      end
    end
  end
end

OData::AbstractSchema::Base.send(:include, OData::AbstractSchema::Serializable::SchemaInstanceMethods)
OData::AbstractSchema::EntityType.send(:include, OData::AbstractSchema::Serializable::EntityTypeInstanceMethods)
