module EmptyEye
  class ViewExtension

    def initialize(association)
      @association = association
    end

    def self.connection
      ActiveRecord::Base.connection
    end
    
    def association
      @association
    end
    
    def parent
      association.active_record
    end
    
    def shard
      association.klass
    end
    
    def shard_suffix
      "#{name.classify}Shard"
    end
    
    def primary
      false
    end
    
    def table
      association.table_name
    end
    
    def name
      association.name
    end
    
    def arel_table
      t = Arel::Table.new(table)
      t.table_alias = name if name != table
      t
    end

    def foreign_key
      association.foreign_key 
    end
    #user declared exceptions ... exclude these attributes calls from parent
    def exceptions
      @exceptions ||= association.options[:except].to_a.collect(&:to_s)
    end
    
    def restrictions
      @restrictions ||= association.options[:only].to_a.collect(&:to_s)
      @restrictions.empty? ? columns : @restrictions
    end

    #exclude for both sql and attribute calls
    def exclude_always
      if primary
        []
      else
        ['id','created_at','updated_at','deleted_at', 'type', foreign_key]
      end 
    end

    #we want to omit these columns
    def exclude
      @exclude ||= exceptions | exclude_always
    end

    def columns
      @columns ||= self.class.connection.columns(table).collect(&:name)
    end

    #the table columns that will be extended in sql
    def columns_with_exceptions
      restrictions - exclude_always
    end
  end
end