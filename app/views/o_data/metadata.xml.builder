xml.instruct!
xml.edmx(:Edmx, :Version => "1.0", "xmlns:edmx" => "http://schemas.microsoft.com/ado/2007/06/edmx", "xml:base" => o_data_metadata_url, "xml:id" => "") do
  xml.edmx(:DataServices, "m:DataServiceVersion" => "2.0", "xmlns:m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata") do
    xml.tag!(:Schema, :Namespace => ODataController.schema.namespace, "xmlns:d" => "http://schemas.microsoft.com/ado/2007/08/dataservices", "xmlns" => "http://schemas.microsoft.com/ado/2007/05/edm", "xml:id" => "Schema") do
      ODataController.schema.entity_types.sort_by(&:qualified_name).each do |entity_type|
        xml.tag!(:EntityType, :Name => entity_type.name) do
          unless entity_type.key_property.blank?
            xml.tag!(:Key) do
              xml.tag!(:PropertyRef, :Name => entity_type.key_property.name)
            end
          end
          
          entity_type.properties.each do |property|
            property_attrs = { :Name => property.name, :Type => property.return_type, :Nullable => property.nullable? }

            property_attrs.merge!("m:FC_TargetPath" => "SyndicationTitle", "m:FC_ContentKind" => "text", "m:FC_KeepInContent" => "true") if property == entity_type.atom_title_property
            property_attrs.merge!("m:FC_TargetPath" => "SyndicationSummary", "m:FC_ContentKind" => "text", "m:FC_KeepInContent" => "false") if property == entity_type.atom_summary_property
            property_attrs.merge!("m:FC_TargetPath" => "SyndicationUpdated", "m:FC_ContentKind" => "text", "m:FC_KeepInContent" => "true") if property == entity_type.atom_updated_at_property
            
            xml.tag!(:Property, property_attrs)
          end
          
          entity_type.navigation_properties.sort_by(&:qualified_name).each do |navigation_property|
            xml.tag!(:NavigationProperty, :Name => navigation_property.name, :Relationship => navigation_property.association.qualified_name, :FromRole => navigation_property.from_end.name, :ToRole => navigation_property.to_end.name)
          end
        end
      end
      
      ODataController.schema.associations.sort_by(&:qualified_name).each do |association|
        xml.tag!(:Association, :Name => association.name) do
          xml.tag!(:End, :Role => association.from_end.name, :Type => association.from_end.return_type, :Multiplicity => association.from_end.to_multiplicity)
          xml.tag!(:End, :Role => association.to_end.name, :Type => association.to_end.return_type, :Multiplicity => association.to_end.to_multiplicity)
          xml.tag!(:ReferentialConstraint) do
            xml.tag!(:Dependent, :Role => association.from_end.name) do
              OData::ActiveRecordSchema::Association.column_names_for_from_end(association.reflection).each do |column_name|
                xml.tag!(:PropertyRef, :Name => column_name)
              end
            end
            xml.tag!(:Principal, :Role => association.to_end.name) do
              OData::ActiveRecordSchema::Association.column_names_for_to_end(association.reflection).each do |column_name|
                xml.tag!(:PropertyRef, :Name => column_name)
              end
            end
          end
        end
      end
      
      xml.tag!(:EntityContainer, :Name => ODataController.schema.namespace, "m:IsDefaultEntityContainer" => true) do
        ODataController.schema.entity_types.sort_by(&:qualified_name).each do |entity_type|
          xml.tag!(:EntitySet, :Name => entity_type.plural_name, :EntityType => entity_type.qualified_name)
        end
        
        ODataController.schema.associations.sort_by(&:qualified_name).each do |association|
          xml.tag!(:AssociationSet, :Name => association.name, :Association => association.qualified_name) do
            xml.tag!(:End, :EntitySet => association.from_end.entity_type.plural_name, :Role => association.from_end.name)
            xml.tag!(:End, :EntitySet => association.reflection.options[:polymorphic] ? association.to_end.return_type : association.to_end.entity_type.plural_name, :Role => association.to_end.name)
          end
        end
      end
    end
  end
end
