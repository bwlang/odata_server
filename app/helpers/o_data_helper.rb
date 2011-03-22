module ODataHelper
  @@o_data_atom_xmlns = { 
    "xmlns"   => "http://www.w3.org/2005/Atom",
    "xmlns:d" => "http://schemas.microsoft.com/ado/2007/08/dataservices", 
    "xmlns:m" => "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata" 
  }.freeze
  
  def o_data_atom_feed(xml, query, results, options = {})
    results_href, results_url = begin
      if base_href = options.delete(:href)
        [base_href.to_s, o_data_resource_url(base_href.to_s)]
      else
        [query.resource_path, o_data_resource_url(query.to_uri)]
      end
    end
    
    results_title = options.delete(:title) || results_href
    
    xml.tag!(:feed, { "xml:base" => o_data_service_url }.merge(options[:hide_xmlns] ? {} : @@o_data_atom_xmlns)) do
      xml.tag!(:title, results_title)
      xml.tag!(:id, results_url)
      xml.tag!(:link, :rel => "self", :title => results_title, :href => results_href)

      unless results.empty?
        if last_result = results.last
          if atom_updated_at = query.schema.atom_updated_at_for(last_result)
            xml.tag!(:updated, atom_updated_at.iso8601)
          end
        end
        
        results.each do |result|
          o_data_atom_entry(xml, query, result, options.merge(:hide_xmlns => true, :href => results_href))
        end
      end
      
      if inlinecount_option = query.options.find { |o| o.option_name == OData::AbstractQuery::Options::InlinecountOption.option_name }
        if inlinecount_option.value == 'allpages'
          xml.m(:count, results.length)
        end
      end
    end
  end
  
  def o_data_atom_entry(xml, query, result, options = {})
    entity_type = options[:entity_type] || query.schema.find_entity_type(:active_record => result.class)
    raise OData::AbstractQuery::Errors::EntityTypeNotFound.new(query, result.class.name) if entity_type.blank?
    
    result_href = entity_type.href_for(result)
    result_url = o_data_resource_url(result_href)
    
    result_title = entity_type.atom_title_for(result)
    result_summary = entity_type.atom_summary_for(result)
    result_updated_at = entity_type.atom_updated_at_for(result)
    
    xml.tag!(:entry, {}.merge(options[:hide_xmlns] ? {} : @@o_data_atom_xmlns)) do
      xml.tag!(:id, result_url) unless result_href.blank?     
      xml.tag!(:title, result_title, :type => "text") unless result_title.blank?
      xml.tag!(:summary, result_summary, :type => "text") unless result_summary.blank?
      xml.tag!(:updated, result_updated_at.iso8601) unless result_updated_at.blank?
      
      xml.tag!(:author) do
        xml.tag!(:name)
      end
      
      xml.tag!(:link, :rel => "edit", :title => result_title, :href => result_href) unless result_title.blank? || result_href.blank?
      
      unless entity_type.navigation_properties.empty?
        entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
          navigation_property_href = result_href + '/' + navigation_property.name
          
          navigation_property_attrs = { :rel => "http://schemas.microsoft.com/ado/2007/08/dataservices/related/" + navigation_property.name, :type => "application/atom+xml;type=#{navigation_property.to_end.multiple? ? 'feed' : 'entry'}", :title => navigation_property.name, :href => navigation_property_href }
          
          if (options[:expand] || {}).keys.include?(navigation_property)
            xml.tag!(:link, navigation_property_attrs) do
              xml.m(:inline, :type => navigation_property_attrs[:type]) do
                if navigation_property.to_end.multiple?
                  o_data_atom_feed(xml, query, navigation_property.find_all(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property]))
                else
                  o_data_atom_entry(xml, query, navigation_property.find_one(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property]))
                end
              end
            end
          else
            xml.tag!(:link, navigation_property_attrs)
          end
        end
      end
      
      xml.tag!(:category, :term => entity_type.qualified_name, :scheme => "http://schemas.microsoft.com/ado/2007/08/dataservices/scheme")
      
      unless (properties = get_selected_properties_for(query, entity_type)).empty?
        xml.tag!(:content, :type => "application/xml") do
          xml.m(:properties) do
            properties.each do |property|
              property_attrs = { "m:type" => property.return_type }
              
              unless (value = property.value_for(result)).blank?
                xml.d(property.name.to_sym, value, property_attrs)
              else
                xml.d(property.name.to_sym, property_attrs.merge("m:null" => true))
              end
            end
          end
        end
      end
    end
  end

  def o_data_json_feed(query, results, options = {})
    results_json = results.collect { |result| o_data_json_entry(query, result, options.merge(:d => false, :deferred => false)) }
    
    if inlinecount_option = query.options.find { |o| o.option_name == OData::AbstractQuery::Options::InlinecountOption.option_name }
      if inlinecount_option.value == 'allpages'
        _json = {
          "results" => results_json,
          "__count" => results.length
        }
        
        return options[:d] ? { "d" => _json } : _json
      end
    end
    
    options[:d] ? { "d" => results_json } : results_json
  end
  
  def o_data_json_entry(query, result, options = {})
    entity_type = options[:entity_type] || query.schema.find_entity_type(:active_record => result.class)
    raise OData::AbstractQuery::Errors::EntityTypeNotFound.new(query, result.class.name) if entity_type.blank?
    
    resource_uri = o_data_resource_url(entity_type.href_for(result))
    resource_type = entity_type.qualified_name
    
    json = begin
      if options[:deferred]
        {
          "__deferred" => { 
            "uri" => resource_uri 
          } 
        }
      else
        _json = { 
          "__metadata" => {
            "uri" => resource_uri,
            "type" => resource_type
          } 
        }
        
        get_selected_properties_for(query, entity_type).each do |property|
          unless %w{__deferred __metadata}.include?(property.name.to_s)
            _json[property.name.to_s] = property.value_for(result)
          else
            # TODO: raise JSONException (property with reserved name)
          end
        end

        entity_type.navigation_properties.sort_by(&:name).each do |navigation_property|
          unless %w{__deferred __metadata}.include?(navigation_property.name.to_s)
            navigation_property_uri = resource_uri + '/' + navigation_property.name.to_s
            
            _json[navigation_property.name.to_s] = begin
              if (options[:expand] || {}).keys.include?(navigation_property)
                if navigation_property.to_end.multiple?
                  o_data_json_feed(query, navigation_property.find_all(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property], :d => false))
                else
                  o_data_json_entry(query, navigation_property.find_one(result), options.merge(:entity_type => navigation_property.to_end.entity_type, :expand => options[:expand][navigation_property], :d => false))
                end
              else
                {
                  "__deferred" => {
                    "uri" => navigation_property_uri
                  }
                }
              end
            end
          else
            # TODO: raise JSONException (navigation property with reserved name)
          end
        end
        
        _json
      end
    end
    
    options[:d] ? { "d" => json } : json
  end
  
  protected
  
  def get_selected_properties_for(query, entity_type)
    if select_option = query.options.find { |o| o.option_name == OData::AbstractQuery::Options::SelectOption.option_name }
      if select_option.entity_type == entity_type
        # entity_type is the $select'ed collection/navigation property
        return select_option.properties
      else
        # entity_type is an $expand'ed navigation property
        return []
      end
    end
    
    # $select option not supplied
    entity_type.properties
  end
end
