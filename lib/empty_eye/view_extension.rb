module EmptyEye
  class ViewExtension
    
    attr_accessor :primary, :shard

    def initialize(name, options)
      @table = name
      @foreign_key = options[:foreign_key].to_s
      @primary_key = options[:primary_key].to_s
      @exceptions = options[:except].to_a.collect(&:to_s)
    end
    
    def shard_suffix
      "#{table.to_s.classify}Shard"
    end
    
    def shard_association_name
      table.singularize
    end
    
    def table
      @table
    end

    def foreign_key
      primary ? nil : @foreign_key 
    end
    
    def key
      primary ? (@primary_key || "id") : nil
    end

    #user declared exceptions ... exclude these attributes calls from parent
    def exceptions
      @exceptions
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
      exceptions | exclude_always
    end

    def columns
      @columns ||= connection.columns(table).collect(&:name)
    end

    #the table columns that will be extended in sql
    def columns_with_exceptions
      columns - exclude_always
    end
    
    private
    
    def connection
      ActiveRecord::Base.connection
    end
  end
end