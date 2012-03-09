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
    
    def association(assoc)
      new_extension = ViewExtension.new(assoc)
      array.reject! {|extension| new_extension.name == extension.name}
      array.push(new_extension)
      new_extension
    end
    
    def primary_table(table)
      @primary = PrimaryViewExtension.new(table, parent)
      array.push(primary)
    end
    
    def create_view_sql
      map_columns_and_associations
      query = primary_arel_table
      
      column_mapping.each do |column, table_alias|
        query = query.project(arel_tables[table_alias][column.to_sym])
      end
      
      without_primary.each do |join_ext|
        current = arel_tables[join_ext.name]
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
      arel_tables[primary.name]
    end
    
    def tables
      array.map(&:table)
    end
    
    def arel_tables
      @arel_tables ||= create_arel_tables
    end
    
    def create_arel_tables
      array.inject({}) do |res,ext|
        res[ext.name] = ext.arel_table
        res
      end
    end
    
    def map_columns_and_associations
      column_mapping.clear
      array.each_with_index do |ext|
        primary.have_one(ext) unless ext.primary
        ext.columns_with_exceptions.each do |col|
          if column_mapping[col.to_sym].nil?
            column_mapping[col.to_sym] ||= ext.name
            primary.delegate_to(col, ext) unless ext.primary
          end
        end
      end
      column_mapping
    end
    
    def without_primary
      array.select {|ext| ext != primary}
    end
  end
end