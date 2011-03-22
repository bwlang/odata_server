xml.instruct!

if @countable
  o_data_atom_feed(xml, @query, @results, :expand => @expand_navigation_property_paths)
else
  first_result = [@results].flatten.compact.first
  o_data_atom_entry(xml, @query, first_result, :expand => @expand_navigation_property_paths)
end
