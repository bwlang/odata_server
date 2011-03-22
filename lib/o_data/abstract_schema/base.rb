module OData
  module AbstractSchema
    class Base
      attr_accessor :namespace
      attr_accessor :entity_types

      def initialize(namespace = "OData")
        @namespace = namespace

        @entity_types = []
      end

      def Association(*args)
        Association.new(self, *args)
      end

      def EntityType(*args)
        entity_type = EntityType.new(self, *args)
        @entity_types << entity_type
        entity_type
      end

      def associations
        @entity_types.collect(&:navigation_properties).flatten.collect(&:association).uniq
      end
      
      def find_entity_type(options = {})
        if options[:name]
          self.entity_types.find { |et| et.name == options[:name].to_s }
        else
          nil
        end
      end

      def qualify(str)
        namespace.to_s + '.' + str.to_s
      end

      def inspect
        "#<< #{namespace.to_s}(#{@entity_types.collect(&:name).join(', ')}) >>"
      end
      
      def to_json
        { "d" => { "EntitySets" => @entity_types.collect(&:plural_name).sort } }.to_json
      end
    end
  end
end
