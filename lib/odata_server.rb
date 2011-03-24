module OData
  class ODataException < StandardError
    def to_s
      "An unknown #{self.class.name.demodulize.to_s} has occured."
    end
  end
end

require "o_data/abstract_schema"
require "o_data/abstract_query"

require "o_data/active_record_schema"
