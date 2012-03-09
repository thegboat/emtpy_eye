module EmptyEye
  class PrimaryViewExtension

    def initialize(table_name, parent)
      @table = table_name
      @parent = parent
      create_shard
    end

    def self.connection
      ActiveRecord::Base.connection
    end
    
    def parent
      @parent
    end
    
    def primary
      true
    end
    
    def shard
      @shard
    end
    
    def table
      @table
    end
    
    def name
      @table
    end
    
    def arel_table
      t = Arel::Table.new(table)
      t.table_alias = name if name != table
      t
    end
    
    def key
      "id"
    end

    def columns
      @columns ||= self.class.connection.columns(table).collect(&:name)
    end

    #the table columns that will be extended in sql
    def columns_with_exceptions
      columns
    end
    
    def have_one(ext)
      mimic = ext.association
      return if shard.reflect_on_association(mimic.name)
      options = mimic.options.dup
      options.merge!(default_has_one_options)
      options.merge!(:foreign_key => ext.foreign_key)
      shard.send(mimic.macro, mimic.name, options)
    end
    
    def delegate_to(col, ext)
      shard.send(:delegate, "#{col}=", {:to => ext.name})
    end
    
    private
    
    def default_has_one_options
      {:autosave => true, :validate => true, :dependent => :destroy}
    end
    
    def create_shard
      new_class = Class.new(Shard)
      new_class.table_name = table
      new_class.mti_master_class = parent
      @shard = EmptyEye.const_set("#{parent.to_s}Shard", new_class)
    end
    
  end
end