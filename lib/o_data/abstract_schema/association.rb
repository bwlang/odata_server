module OData
  module AbstractSchema
    class Association < SchemaObject
      cattr_reader :polymorphic_namespace_name
      @@polymorphic_namespace_name = '$polymorphic'
      
      attr_accessor :from_end, :to_end
    
      def initialize(schema, name, from_end_options = {}, to_end_options = {})
        super(schema, name)
      
        self.FromEnd(from_end_options.delete(:entity_type), from_end_options.delete(:return_type), from_end_options.delete(:name), from_end_options)
        self.ToEnd(to_end_options.delete(:entity_type), to_end_options.delete(:return_type), to_end_options.delete(:name), to_end_options)
      end
      
      def FromEnd(*args)
        @from_end = End.new(self.schema, self, *args)
      end
      
      def ToEnd(*args)
        @to_end = End.new(self.schema, self, *args)
      end
      
      def inspect
        "#<< #{qualified_name.to_s}(#{[@from_end, @to_end].flatten.collect { |e| "#{e.name.to_s}: #{e.return_type.to_s}" }.join(", ")}) >>"
      end
    end
  end
end
