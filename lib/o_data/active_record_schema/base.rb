module OData
  module ActiveRecordSchema
    class Base < OData::AbstractSchema::Base
      def find_entity_type(options = {})
        if options[:active_record]
          self.entity_types.find { |et| et.name == EntityType.name_for(options[:active_record]) }
        else
          super(options)
        end
      end
      
      def initialize(*args)
        super(*args)
        
        Dir.glob(RAILS_ROOT + '/app/models/*.rb').each { |file| require file }
        
        Object.subclasses_of(ActiveRecord::Base).collect { |active_record|
          self.EntityType(active_record, :reflect_on_associations => false)
        }.collect { |entity_type| 
          entity_type.active_record.reflect_on_all_associations.each do |reflection|
            entity_type.NavigationProperty(reflection)
          end
        }
      end
      
      def Association(*args)
        Association.new(self, *args)
      end

      def EntityType(*args)
        entity_type = EntityType.new(self, *args)
        self.entity_types << entity_type
        entity_type
      end
    end
  end
end
