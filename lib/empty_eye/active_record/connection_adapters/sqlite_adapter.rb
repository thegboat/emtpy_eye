module ActiveRecord
  module ConnectionAdapters
    class SQLiteAdapter

      def tables(name = 'SCHEMA', table_name = nil) #:nodoc:
        sql = <<-SQL
          SELECT name
          FROM sqlite_master
          WHERE (type = 'table' OR type = 'view') AND NOT name = 'sqlite_sequence'
        SQL
        sql << " AND name = #{quote_table_name(table_name)}" if table_name

        exec_query(sql, name).map do |row|
          row['name']
        end
      end
      
      def tables_without_views(name = 'SCHEMA', table_name = nil) #:nodoc:
        sql = <<-SQL
          SELECT name
          FROM sqlite_master
          WHERE type = 'table' AND NOT name = 'sqlite_sequence'
        SQL
        sql << " AND name = #{quote_table_name(table_name)}" if table_name

        exec_query(sql, name).map do |row|
          row['name']
        end
      end
      
      def views(name = 'SCHEMA', table_name = nil) #:nodoc:
        sql = <<-SQL
          SELECT name
          FROM sqlite_master
          WHERE type = 'view' AND NOT name = 'sqlite_sequence'
        SQL
        sql << " AND name = #{quote_table_name(table_name)}" if table_name

        exec_query(sql, name).map do |row|
          row['name']
        end
      end
    end
  end
end