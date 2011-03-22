module OData
  module AbstractSchema
    class End < SchemaObject
      cattr_reader :end_option_names
      @@end_option_names = %w{nullable multiple polymorphic}
      
      @@end_option_names.each do |option_name|
        define_method(:"#{option_name.to_s}?") do
          !!self.options[option_name.to_sym]
        end
      end

      attr_reader :association
      attr_reader :entity_type, :return_type
      attr_accessor :options

      def initialize(schema, association, entity_type, return_type, name, options = {})
        super(schema, name)
        
        @association = association
        @entity_type = entity_type
        @return_type = return_type
        
        unless @entity_type.nil?
          @return_type ||= @entity_type.qualified_name
        end

        @options = {}
        options.keys.select { |key| @@end_option_names.include?(key.to_s) }.each do |key|
          @options[key.to_sym] = options[key]
        end
      end
      
      # def return_type
      #   @options[:multiple] ? 'Collection(' + @return_type.to_s + ')' : @return_type.to_s
      # end

      def to_multiplicity
        m = (@options[:nullable] ? '0' : '1') + '..' + (@options[:multiple] ? '*' : '1')
        m = '1' if m == '1..1'
        m = '*' if m == '0..*'
        m
      end
      
      def inspect
        "#<< #{qualified_name.to_s}(return_type: #{@return_type.to_s}, to_multiplicity: #{to_multiplicity.to_s}) >>"
      end
    end
  end
end
