module EmptyEye
  class PrimaryViewExtension
    
    #primary extension for parent class
    #manages associations for database updates
    #has many of the same interfaces as view extensions

    def initialize(table_name, parent)
      @table = table_name
      @parent = parent
      create_shard
    end

    def self.connection
      ActiveRecord::Base.connection
    end
    
    #never include the type field as it shouldnt be needed and cant be updated anyway
    def self.exclude_always
      ['type']
    end
    
    #class to which this extension belongs
    def parent
      @parent
    end
    
    #to let the outside word know it is primary
    def primary
      true
    end
    
    #class that will mimic the associations of the parent for updating db
    def shard
      @shard
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
    
    #this may change but for now the key is the primary id of the parent and shard
    def key
      arel_table[:id]
    end
    
    def foreign_key
      "id"
    end
    
    def sti_also?
      !parent.descends_from_active_record?
    end
    
    #arel column of type field
    def type_column
      if sti_also? 
        arel_table[parent.inheritance_column.to_sym]
      end
    end
    
    #value of the polymorphic column
    def type_value
      parent.name if type_column
    end
    
    #always null for primary
    def polymorphic_type
      nil
    end

    #table columns
    def table_columns
      self.class.connection.columns(table).collect(&:name)
    end
    
    def exclude
      self.class.exclude_always
    end

    #the table columns that will be extended in sql
    def columns
      table_columns - exclude
    end
    
    #create associations for shard class to mimic parent
    def have_one(ext)
      #this is myself; dont associate
      return if ext.primary
      mimic = ext.association
      return if shard.reflect_on_association(mimic.name)
      options = mimic.options.dup
      options.merge!(default_has_one_options)
      options.merge!(:foreign_key => ext.foreign_key)
      shard.send(mimic.macro, mimic.name, options)
    end
    
    #delegate setters to appropriate associations
    def delegate_to(col, ext)
      return if ext.primary
      shard.send(:delegate, "#{col}=", {:to => ext.name})
    end
    
    private
    
    #MTI wouldnt make any sense if these were not forced in the associations
    def default_has_one_options
      {:autosave => true, :validate => true, :dependent => :destroy}
    end

    #if possible shard inherits from the superclass
    def shard_inherit_from
      parent.base_class == parent ? ActiveRecord::Base : parent.send(:superclass)
    end
    
    #create a class to manage the parents associations
    def create_shard
      new_class = Class.new(shard_inherit_from)
      new_class.send(:include, Shard)
      new_class.table_name = table
      new_class.mti_master_class = parent
      @shard = EmptyEye.const_set("#{parent.to_s}Shard", new_class)
    end
    
  end
end