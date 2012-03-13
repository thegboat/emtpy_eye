module EmptyEye
  class ShardCollection
    
    #a collection of all the view_shards
    #these are wranglers for the shards
    #uses 'array' as a proxy
    #performs array methods by passing things off in method missing
    
    def initialize(primary_shard_klass)
      @master_class = primary_shard_klass.master_class
      @primary = PrimaryShard.new(primary_shard_klass)
      @array = [@primary]
    end
    
    #the proxy object for instances
    def array
      @array
    end
    
    #we want to see the proxy object not the class info
    def inspect
      array.inspect
    end
    
    #the class to which the shards belongs
    def master_class
      @master_class
    end
    
    def descend(klass)
      @master_class = klass
      self
    end
    
    #add shard based on association from master_class
    def create_with(assoc)
      new_shard = Shard.new(assoc)
      reject! {|shard| shard.name == new_shard.name}
      push(new_shard)
      new_shard
    end
    
    def schema_version
      @schema_version
    end
    
    #takes the name of shard and a hash of intended updates from master instance
    #returns a subset of hash with only values the shard handles
    def delegate_map(name, hash)
      keys = update_mapping[name] & hash.keys
      keys.inject({}) do |res, col|
        res[col] = hash[col] if hash[col]
        res
      end
    end

    #the primary shard
    def primary
      @primary
    end
    
    #array of shard classes
    def klasses
      map(&:klass)
    end
    
    def names
      map(&:name)
    end
    
    #this object responds to array methods
    def respond_to?(m)
      super || array.respond_to?(m)
    end
    
    #delegate to the array proxy when the method is missing
    def method_missing(m, *args, &block)
      if respond_to?(m)
        array.send(m, *args, &block)
      else
        super
      end
    end
    
    def view_sql
      @view_sql
    end
    
    #generates view sql
    def create_view_sql
      #determine what shard will handle what columns
      map_attribute_management
      #start with primary table
      query = primary_arel_table
      
      #build select clause with correct table handling the appropriate columns
      query = query.project(*arel_columns)
      
      #build joins
      each do |shard|
        next if shard.primary
        current = shard.arel_table
        key = shard.foreign_key.to_sym
        if shard.type_column
          query.join(current).on(
            primary.key.eq(current[key]), shard.type_column.eq(shard.type_value)
          )
        else
          query.join(current).on(
            primary.key.eq(current[key])
          )
        end
      end
      
      #we dont need to keep this data
      free_arel_columns
      
      #STI condition if needed
      if primary.sti_also?
        query.where(primary.type_column.eq(primary.type_value))
      end
      
      #build view creation statement
      @view_sql = "CREATE VIEW #{primary.klass.compute_view_name} AS\n#{query.to_sql}"
    end
    
    private
    
    def schema_version=(md5_hash)
      @schema_version = md5_hash
    end
    
    #all of the arel columns mapped to the right arel tables
    def arel_columns
      @arel_columns ||= []
    end
    
    #we dont need to keep this data
    def free_arel_columns
      @arel_columns = nil
    end
    
    #tracks the attributes with the shard that will handle it
    def update_mapping
      @update_mapping ||= {}
    end
    
    #generate a foreign_key if it is missing
    def default_foreign_key
      view_name = master_class.table_name.singularize
      "#{view_name}_id"
    end
    
    #the primary arel table
    def primary_arel_table
      primary.arel_table
    end
    
    #all the tables
    def tables
      map(&:table)
    end
    
    #map the columns to the shard that will handle it
    def map_attribute_management
      #clear out what we know
      arel_columns.clear
      #use this to track and remove dupes
      tracker = {}
      each do |shard|
        #mimic the master_class's associations through primary shard
        primary.has_another(shard)
        shard.columns.each do |col|
          column = col.to_sym
          #skip if we already have this column
          next if tracker[column]
          #set to true so we wont do again
          tracker[column] = true
          #add the column based on the shard's arel_table
          arel_columns << shard.arel_table[column]
          #later we need to know how to update thing correctly
          update_mapping[shard.name] = update_mapping[shard.name].to_a << col
          #delegate the setter for column to klass of shard through primary shard
          primary.delegate_to(column, shard) unless shard.primary
        end
      end
    end
  end
end