module EmptyEye
  class PrimaryShard
    
    #primary shard for master_class class
    #manages associations for database updates
    #has many of the same interfaces as view shards

    def initialize(wrangler)
      @table = wrangler.table_name
      @master_class = wrangler.master_class
      @klass = wrangler
    end

    def self.connection
      ActiveRecord::Base.connection
    end
    
    #never include the type field as it shouldnt be needed and cant be updated anyway
    def self.exclude_always
      ['type', 'mti_schema_version']
    end
    
    #class to which this shard belongs
    def master_class
      @master_class
    end
    
    #to let the outside word know it is primary
    def primary
      true
    end
    
    #class that will mimic the associations of the master_class for updating db
    def klass
      @klass
    end
    
    # the tablename
    def table
      @table
    end
    
    # the alias for the table; for primary we just use the table name
    def name
      @table
    end
    
    # arel table for generating the view
    def arel_table
      @arel_table ||= Arel::Table.new(table)
    end
    
    #this may change but for now the key is the primary id of the master_class and shard
    def key
      arel_table[:id]
    end
    
    def foreign_key
      "id"
    end
    
    def sti_also?
      !master_class.descends_from_active_record?
    end
    
    #arel column of type field
    def type_column
      if sti_also? 
        arel_table[master_class.inheritance_column.to_sym]
      end
    end
    
    #value of the polymorphic column
    def type_value
      master_class.name if type_column
    end
    
    #always null for primary
    def polymorphic_type
      nil
    end

    #table columns
    def table_columns
      klass.column_names
      #self.class.connection.columns(table).collect(&:name)
    end
    
    def exclude
      self.class.exclude_always
    end

    #the table columns that will be extended in sql
    def columns
      table_columns - exclude
    end
    
    #create associations for shard class to mimic master_class
    def has_another(shard)
      #this is myself; dont associate
      return if shard.primary
      mimic = shard.association
      return if klass.reflect_on_association(mimic.name)
      options = mimic.options.dup
      options.merge!(default_has_one_options)
      options.merge!(:foreign_key => shard.foreign_key)
      klass.send(mimic.macro, mimic.name, options)
    end
    
    #delegate setters to appropriate associations
    def delegate_to(col, shard)
      return if shard.primary
      klass.send(:delegate, "#{col}=", {:to => shard.name})
    end
    
    private
    
    #MTI wouldnt make any sense if these were not forced in the associations
    def default_has_one_options
      {:autosave => true, :validate => true, :dependent => :destroy}
    end
    
  end
end