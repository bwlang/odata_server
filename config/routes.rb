ActionController::Routing::Routes.draw do |map|
  map.with_options(:controller => "o_data") do |o_data|
    o_data.o_data_service  "/OData/OData.svc",                                     :action => "service"
    o_data.o_data_metadata "/OData/OData.svc/$metadata",                           :action => "metadata"
    o_data.o_data_resource "/OData/OData.svc/*#{ODataController.path_param.to_s}", :action => "resource"
    
    o_data.connect "/OData",                                     :action => "redirect_to_service"
    o_data.connect "/OData/$metadata",                           :action => "redirect_to_metadata"
    o_data.connect "/OData/*#{ODataController.path_param.to_s}", :action => "redirect_to_resource"
  end
end
