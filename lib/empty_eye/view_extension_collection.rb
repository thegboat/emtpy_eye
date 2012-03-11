module EmptyEye
  class ViewExtensionCollection
    
    def initialize(parent)
      @parent = parent
      @array = []
    end
    
    #the proxy object for instances
    def array
      @array
    end
    
    #we want to see the proxy object not the class info
    def inspect
      array.inspect
    end
    
    #the class to which the instance belongs
    def parent
      @parent
    end
    
    def descend(klass)
      @parent = klass
      self
    end
    
    #add extensions based on association from parent
    def association(assoc)
      new_extension = ViewExtension.new(assoc)
      reject! {|extension| new_extension.name == extension.name}
      push(new_extension)
      new_extension
    end
    
    #add primary extension; needs a table only
    def primary_table(table)
      push(@primary = PrimaryViewExtension.new(table, parent))
    end
    
    #generates view sql
    def create_view_sql
      #determine what shard will handle what columns
      map_attribute_management
      #start with primary table
      query = primary_arel_table
      
      #build select clause with correct table handling the appropriate columns
      arel_columns.each do |arel_column|
        query = query.project(arel_column)
      end
      
      #build joins
      without_primary.each do |ext|
        current = ext.arel_table
        key = ext.foreign_key.to_sym
        if ext.type_column
          query = query.join(current).on(
            primary.key.eq(current[key]), ext.type_column.eq(ext.type_value)
          )
        else
          query = query.join(current).on(
            primary.key.eq(current[key])
          )
        end
      end
      
      #merge create command with select column
      "CREATE VIEW #{parent.table_name} AS\n#{query.to_sql}"
    end
    
    def arel_columns
      @arel_columns ||= []
    end
    
    def update_mapping
      @update_mapping ||= {}
    end
    
    def delegate_map(name, hash)
      keys = update_mapping[name] & hash.keys
      keys.inject({}) do |res, col|
        res[col] = hash[col] if hash[col]
        res
      end
    end
    
    def validations
      @validations ||= []
    end

    #the primary extension
    def primary
      @primary
    end
    
    #array of shard classes
    def shards
      map(&:shard)
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
    
    private
    
    #generate a foreign_key if it is missing
    def default_foreign_key
      view_name = parent.table_name.singularize
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
    
    #map the columns to the extension that will handle it
    def map_attribute_management
      #clear out what we know
      arel_columns.clear
      #use this to track and remove dupes
      tracker = {}
      each do |ext|
        #mimic the parent's associations through primary shard
        primary.have_one(ext)
        ext.columns.each do |col|
          column = col.to_sym
          #skip if we already have this column
          next if tracker[column]
          #set to true so we wont do again
          tracker[column] = true
          #add the column based on the extension's arel_table
          arel_columns << ext.arel_table[column]
          #later we need to know how to update thing correctly
          update_mapping[ext.name] = update_mapping[ext.name].to_a << col
          #delegate the setter for column to shard of extension through primary shard
          primary.delegate_to(column, ext) unless ext.primary
          #mti class must inherit validations
          add_validations(column, ext) 
        end
      end
    end
    
    def add_validations(column, ext)
      return unless ext.shard._validators[column].present?
      return if ext.primary
      rtn = ext.shard._validators[column].each do |validator|
        meth = case validator.class.to_s
        when /presence/i then :validates_presence_of
        when /acceptance/i then :validates_acceptance_of
        when /numericality/i then :validates_numericality_of
        when /length/i then :validates_length_of
        when /inclusion/i then :validates_inclusion_of
        when /format/i then :validates_format_of
        when /exclusion/i then :validates_exclusion_of
        when /confirmation/i then :validates_confirmation_of
        when /uniqueness/i then :validates_uniqueness_of
        else nil
        end
        if meth
          args = []
          args << meth
          args << column
          args << validator.options
          validations << args
        end
      end
    end
    
    #return a list of extensions without primary
    def without_primary
      array.select {|ext| ext != primary}
    end
  end
end