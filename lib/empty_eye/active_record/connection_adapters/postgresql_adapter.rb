module ActiveRecord
  module ConnectionAdapters
    class PostgreSQLAdapter < AbstractAdapter
      
      def tables(name = nil)
        tables_without_views(name) | views(name)
      end
      
      def tables_without_views(name = nil)
        query(<<-SQL, 'SCHEMA').map { |row| row[0] }
          SELECT tablename
          FROM pg_tables
          WHERE schemaname = ANY (current_schemas(false))
        SQL
      end
      
      def views(name = nil)
        query(<<-SQL, 'SCHEMA').map { |row| row[0] }
          SELECT viewname
          FROM pg_views
          WHERE schemaname = ANY (current_schemas(false))
        SQL
      end
    end
  end
end