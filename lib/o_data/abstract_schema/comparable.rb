module OData
  module AbstractSchema
    module Comparable
      def compare(a, b, property_order_pairs = [])
        _pairs = [] + property_order_pairs
        _compare(a, b, _pairs.shift, _pairs)
      end

      def sort(many, property_order_pairs = [])
        [many].compact.flatten.sort { |a, b| compare(a, b, property_order_pairs) }
      end
      
      protected
      
      def _compare(a, b, head, rest)
        return 0 if head.blank?

        property, asc_or_desc = head
        asc_or_desc ||= :asc

        if b.blank?
          (asc_or_desc == :asc) ? 1 : -1
        else
          a_value = property.value_for(a)
          b_value = property.value_for(b)

          if a_value.blank?
            (asc_or_desc == :asc) ? -1 : 1
          elsif b_value.blank?
            (asc_or_desc == :asc) ? 1 : -1
          elsif (c = a_value <=> b_value) != 0
            (asc_or_desc == :asc) ? c : c * -1
          else
            _compare(a, b, rest.shift, rest)
          end
        end
      end
    end # Comparable
  end # AbstractSchema
end # OData

OData::AbstractSchema::EntityType.send(:include, OData::AbstractSchema::Comparable)
