module EmptyEye
  class ViewExtensionCollection
    
    def initialize(parent)
      @parent = parent
      @array = []
    end
    
    def array
      @array
    end
    
    def inspect
      array.inspect
    end
    
    def parent
      @parent
    end
    
    def add(table_name, options = {})
      new_extension = ViewExtension.new(table_name, options)
      array.reject! {|extension| new_extension.table == extension.table}
      push(new_extension)
      new_extension
    end
    
    def push(new_extension)
      if array.empty?
        new_extension.primary = true
        @primary = new_extension
      end
      array.push(new_extension)
    end
    
    def with_table(table, options = {})
      options.reverse_merge!(:foreign_key => default_foreign_key)
      add(table, options)
    end
    
    def create_view_sql
      map_columns_and_associations
      query = primary_arel_table
      
      column_mapping.each do |column, table|
        query = query.project(arel_tables[table][column.to_sym])
      end
      
      without_primary.each do |join_ext|
        current = arel_tables[join_ext.table]
        key = join_ext.foreign_key.to_sym
        query = query.join(current).on(primary_key.eq(current[key]))
      end
      
      "CREATE VIEW #{parent.table_name} AS\n#{query.to_sql}"
    end

    def column_mapping
      @column_mapping ||= {}
    end

    def primary
      @primary
    end
    
    def shards
      array.map(&:shard)
    end
    
    def respond_to?(m)
      array.respond_to?(m) || super
    end
    
    def method_missing(m, *args, &block)
      if respond_to?(m)
        array.send(m, *args, &block)
      else
        super
      end
    end
    
    private
    
    def default_foreign_key
      view_name = parent.table_name.singularize
      "#{view_name}_id"
    end
    
    def primary_key
      primary_arel_table[:id]
    end
    
    def primary_arel_table
      arel_tables[primary.table]
    end
    
    def tables
      array.map(&:table)
    end
    
    def arel_tables
      @arel_tables ||= create_arel_tables
    end
    
    def create_arel_tables
      tables.inject({}) do |res,name|
        res[name] = Arel::Table.new(name)
        res
      end
    end
    
    def map_columns_and_associations
      column_mapping.clear
      array.each_with_index do |ext|
        ext.shard = create_shard_class(ext)
        make_primary_have_one(ext) unless ext.primary
        ext.columns_with_exceptions.each do |col|
          if column_mapping[col.to_sym].nil?
            column_mapping[col.to_sym] ||= ext.table
            delegate_to(col, ext) unless ext.primary
          end
        end
      end
      column_mapping
    end
    
    def create_shard_class(ext)
      return if "#{parent.to_s}#{ext.shard_suffix}".safe_constantize
      new_class = Class.new(Shard).tap do |c|
        c.table_name = ext.table
        unless ext.primary
          c.belongs_to(primary.table, belongs_to_args.merge(:foreign_key => ext.foreign_key))
        end
      end
      new_class.empty_eye_attributes = filtered_attributes(ext)
      EmptyEye.const_set("#{parent.to_s}#{ext.shard_suffix}", new_class)
    end
    
    def filtered_attributes(ext)
      (ext.columns_with_exceptions - primary.columns_with_exceptions) << ext.foreign_key
    end
    
    def delegate_to(col, ext)
      primary.shard.send(:delegate, "#{col}=", {:to => ext.table})
    end
    
    def belongs_to_args
      {:class_name => "EmptyEye::#{parent.to_s}#{primary.shard_suffix}", :autosave => true}
    end
    
    def make_primary_have_one(ext)
      primary.shard.send(:has_one, ext.table, :class_name => ext.shard.to_s, :dependent => :delete, :foreign_key => ext.foreign_key)
    end
    
    def without_primary
      array.select {|ext| ext.table != primary.table}
    end
  end
end