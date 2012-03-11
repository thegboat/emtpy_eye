module EmptyEye
  class ViewExtension
    
    #extension for parent class
    #tracks associations for database updates managed by primary extension
    #has many of the same interfaces as primary view extension

    def initialize(association)
      @association = association
    end
    
    #exclude from view generation always
    def self.exclude_always
      ['id','created_at','updated_at','deleted_at', 'type']
    end
    
    #association that this extension will build upon
    def association
      @association
    end
    
    #the table columns that will be extended in sql
    def columns
      restrictions - exclude
    end

    #never the primary
    def primary
      false
    end
    
    #table of the shard
    def table
      association.table_name
    end
    
    #name of the association
    def name
      association.name
    end
    
    #used to create view
    def arel_table
      @arel_table ||= begin
        t= Arel::Table.new(table)
        t.table_alias = alias_name if alias_name != table
        t
      end
    end

    #foreign key of the shard; used in view generation and database updates
    def foreign_key
      association.foreign_key 
    end

    #the shard is simply the class of the association
    def shard
      association.klass
    end
    
    #arel column of polymorphic type field
    def type_column
      arel_table[polymorphic_type.to_sym] if polymorphic_type
    end
    
    #value of the polymorphic column
    def type_value
      parent.base_class.name if polymorphic_type
    end

    #value computed to remove this from column map; no need for the view to have it
    def polymorphic_type
      return unless association.options[:as]
      "#{association.options[:as]}_type"
    end
    
    private
    
    #class to whom this extension belongs
    def parent
      association.active_record
    end
    
    #class of the extension table
    def klass
      association.klass
    end
    
    #uses association name to create alias to prevent non unique aliases
    def alias_name
      name.to_s.pluralize
    end
    
    #user declared exceptions ... exclude these columns from the parent inheritance
    def exceptions
      association.options[:except].to_a.collect(&:to_s)
    end
    
    #user declared restrictions ... restrict parent inheritance columns to these
    def restrictions
      only = association.options[:only].to_a.collect(&:to_s)
      only.empty? ? table_columns : only
    end

    #we want to omit these columns
    def exclude
      [exceptions, self.class.exclude_always, foreign_key, polymorphic_type].flatten.uniq
    end

    #all the columns of the extensions table
    def table_columns
      klass.column_names
    end
  end
end