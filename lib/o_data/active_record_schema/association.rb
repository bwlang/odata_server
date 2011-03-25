module OData
  module ActiveRecordSchema
    class Association < OData::AbstractSchema::Association
      def self.name_for(reflection)
        EntityType.name_for(reflection.active_record) + '#' + reflection.name.to_s
      end
      
      def self.nullable?(active_record, association_columns)
        association_columns.all? { |column_name|
          column = active_record.columns.find { |c| c.name == column_name }
          column.blank? ? true : column.null
        }
      end
      
      def self.active_record_for_from_end(reflection)
        reflection.active_record
      end
      
      def self.active_record_for_to_end(reflection)
        return nil if reflection.options[:polymorphic]
        begin
            reflection.class_name.constantize
        rescue => ex
          raise "Failed to handle class <#{reflection.active_record}> #{reflection.macro} #{reflection.name}"
        end
      end

      # def self.foreign_keys_for(reflection)
      #   [reflection.options[:foreign_key] || reflection.association_foreign_key, reflection.options[:foreign_type]].compact
      # end
      
      def self.polymorphic_column_name(reflection, column_name)
        # self.polymorphic_namespace_name.to_s + '.' + (reflection.options[:as] ? reflection.options[:as].to_s.classify : reflection.class_name.to_s) + '#' + column_name.to_s
        self.polymorphic_namespace_name.to_s + '#' + column_name.to_s
      end
      
      def self.column_names_for_from_end(reflection)
        out = []
        
        case reflection.macro
        when :belongs_to
          out << reflection.primary_key_name
          out << reflection.options[:foreign_type] if reflection.options[:polymorphic]
        else
          out << EntityType.primary_key_for(reflection.active_record)
          out << polymorphic_column_name(reflection, 'ReturnType') if reflection.options[:as]
        end
        
        out
      end
      
      def self.column_names_for_to_end(reflection)
        out = []
        
        case reflection.macro
        when :belongs_to
          if reflection.options[:polymorphic]
            out << polymorphic_column_name(reflection, 'Key')
            out << polymorphic_column_name(reflection, 'ReturnType')
          else
            out << EntityType.primary_key_for(reflection.class_name.constantize)
          end
        else
          out << reflection.primary_key_name
          
          if reflection.options[:as]
            out << reflection.options[:as].to_s + '_type'
          end
        end
        
        out
      end
      
      def self.from_end_options_for(schema, reflection)
        active_record = active_record_for_from_end(reflection)
        
        entity_type = schema.find_entity_type(:active_record => active_record)
        raise OData::AbstractQuery::Errors::EntityTypeNotFound.new(nil, active_record.class_name) if entity_type.blank?
        
        polymorphic = false
        
        # TODO: detect 'nullable' for FromEnd of Association
        nullable = false
        
        multiple = reflection.macro == :has_and_belongs_to_many
        
        name = entity_type.name
        name = name.pluralize if multiple
        
        { :name => name, :entity_type => entity_type, :return_type => entity_type.qualified_name, :multiple => multiple, :nullable => nullable, :polymorphic => polymorphic }
      end
      
      def self.to_end_options_for(schema, reflection)
        Rails.logger.info("Processing #{reflection.active_record}")
        active_record = active_record_for_to_end(reflection)
        entity_type = schema.find_entity_type(:active_record => active_record)
        
        polymorphic = reflection.options[:polymorphic] # || reflection.options[:as]

        multiple = [:has_many, :has_and_belongs_to_many].include?(reflection.macro)
        
        nullable = begin
          case reflection.macro
          when :belongs_to
            nullable?(active_record_for_from_end(reflection), column_names_for_from_end(reflection))
          else
            true
          end
        end
        
        name = EntityType.name_for(reflection.class_name)
        name = name.pluralize if multiple
        
        unless active_record.blank? || entity_type.blank?
          { :name => name, :entity_type => entity_type, :return_type => entity_type.qualified_name, :multiple => multiple, :nullable => nullable, :polymorphic => polymorphic }
        else
          { :name => name, :return_type => self.polymorphic_namespace_name, :multiple => multiple, :nullable => nullable, :polymorphic => polymorphic }
        end
      end
      
      attr_reader :reflection
      
      def initialize(schema, reflection)
        super(schema, self.class.name_for(reflection), self.class.from_end_options_for(schema, reflection), self.class.to_end_options_for(schema, reflection))
        
        @reflection = reflection
      end
    end
  end
end
