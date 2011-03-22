class ODataController < ApplicationController
  cattr_reader :path_param
  @@path_param = :__path__.freeze
  
  cattr_reader :schema
  @@schema = OData::ActiveRecordSchema::Base.new.freeze
  
  cattr_reader :parser
  @@parser = OData::AbstractQuery::Parser.new(@@schema).freeze
  
  rescue_from OData::ODataException, :with => :handle_exception
  rescue_from ActiveRecord::RecordNotFound, :with => :handle_exception
  
  before_filter :extract_resource_path_and_query_string, :only => [:resource]
  before_filter :parse_resource_path_and_query_string!,  :only => [:resource]
  before_filter :set_request_format!,                    :only => [:resource]
  
  %w{service metadata resource}.each do |method_name|
    define_method(:"redirect_to_#{method_name}") do
      # redirect_to(send(:"o_data_#{method_name}_url"))
      redirect_to(params.merge(:action => method_name.to_s))
    end
  end
  
  def service
    respond_to do |format|
      format.xml  # service.xml.builder
      format.json { render :json => @@schema.to_json }
    end
  end
  
  def metadata
    respond_to do |format|
      format.xml  # metadata.xml.builder
    end
  end
  
  def resource
    @last_segment = @query.segments.last
    
    @results = @query.execute!
    
    case @last_segment.class.segment_name
    when OData::AbstractQuery::Segments::CountSegment.segment_name
      render :text => @results.to_i
    when OData::AbstractQuery::Segments::LinksSegment.segment_name
      request.format = :xml unless request.format == :json
      
      respond_to do |format|
        format.xml  { render :inline => "xml.instruct!; @results.empty? ? xml.links('xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices') : xml.links('xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices') { @results.each { |r| xml.uri(o_data_resource_url(r[1])) } }", :type => :builder }
        format.json { render :json => { "links" => @results.collect { |r| { "uri" => r } } }.to_json }
      end
    when OData::AbstractQuery::Segments::ValueSegment.segment_name
      render :text => @results.to_s
    when OData::AbstractQuery::Segments::PropertySegment.segment_name
      request.format = :xml unless request.format == :json
      
      respond_to do |format|
        format.xml  { render :inline => "xml.instruct!; value.blank? ? xml.tag!(key.to_sym, 'm:null' => true, 'xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices', 'xmlns:m' => 'http://schemas.microsoft.com/ado/2007/08/dataservices') : xml.tag!(key.to_sym, value, 'edm:Type' => type, 'xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices', 'xmlns:edm' => 'http://schemas.microsoft.com/ado/2007/05/edm')", :locals => { :key => @results.keys.first.name, :type => @results.keys.first.return_type, :value => @results.values.first }, :type => :builder }
        format.json { render :json => { @results.keys.first.name => @results.values.first }.to_json }
      end
    when OData::AbstractQuery::Segments::NavigationPropertySegment.segment_name
      @countable = @last_segment.countable?
      
      @navigation_property = @last_segment.navigation_property
      @polymorphic = @navigation_property.to_end.polymorphic?
      
      if @polymorphic
        @entity_type = nil
        @entity_type_name = @navigation_property.to_end.name.singularize
      else
        @entity_type = @navigation_property.to_end.entity_type
        @entity_type_name = @entity_type.name
      end
      
      @collection_name = @entity_type_name.pluralize
      
      @expand_navigation_property_paths = {}
      if expand_option = @query.options.find { |o| o.option_name == OData::AbstractQuery::Options::ExpandOption.option_name }
        @expand_navigation_property_paths = expand_option.navigation_property_paths
      end
      
      respond_to do |format|
        format.atom # resource.atom.builder
        format.json # resource.json.erb
      end
    when OData::AbstractQuery::Segments::CollectionSegment.segment_name
      @countable = @last_segment.countable?
      
      @navigation_property = nil
      @polymorphic = true
      
      @entity_type = @last_segment.entity_type
      
      @expand_navigation_property_paths = {}
      if expand_option = @query.options.find { |o| o.option_name == OData::AbstractQuery::Options::ExpandOption.option_name }
        @expand_navigation_property_paths = expand_option.navigation_property_paths
      end
      
      respond_to do |format|
        format.atom # resource.atom.builder
        format.json # resource.json.erb
      end
    else
      # in theory, this branch is unreachable because the <tt>parse_resource_path_and_query_string!</tt>
      # method will throw an exception if the <tt>OData::AbstractQuery::Parser</tt> fails to match any
      # segment of the resource path.
      raise OData::AbstractQuery::Errors::AbstractQueryException.new(@query)
    end
  end
  
  private
  
  def extract_resource_path_and_query_string
    @resource_path = params[@@path_param].join('/')
    
    @query_string = params.inject({}) { |acc, pair|
      key, value = pair
      acc[key.to_sym] = value unless [@@path_param, :controller, :action].include?(key.to_sym)
      acc
    }.collect { |key, value|
      key.to_s + '=' + value.to_s
    }.join('&')
  end
  
  def parse_resource_path_and_query_string!
    @query = @@parser.parse!([@resource_path, @query_string].compact.join('?'))
  end
  
  def set_request_format!
    if format_option = @query.options.find { |o| o.option_name == OData::AbstractQuery::Options::FormatOption.option_name }
      if format_value = format_option.value
        request.format = format_value.to_sym
      end
    end
  end
  
  def handle_exception(ex)
    request.format = :xml
    
    respond_to do |format|
      format.xml { render :inline => "xml.instruct!; xml.error('xmlns' => 'http://schemas.microsoft.com/ado/2007/08/dataservices/metadata') { xml.code(code.to_s); xml.message(message); xml.uri(uri) }", :type => :builder, :locals => { :code => nil, :message => ex.message, :uri => request.url } }
    end
  end
end
