module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      #we need this logic to correctly build schema file
      def tables_without_views
        #trying to make compatible with rails 2.3.x
        if respond_to?('execute_and_free')
          execute_and_free(tables_without_views_sql) do |result|
            result.collect { |field| field.first }
          end
        else
          result = execute(tables_without_views_sql)
          rtn = result.collect { |field| field.first }
          result.free rescue nil
          rtn
        end
      end
    
      private
    
      #i coulda made this more OO but this seemed to handle more unknown speed bumps
      #perusing rails_sql_views helped a bit
      # https://github.com/aeden/rails_sql_views
      def tables_without_views_sql
        case self.to_s
        when /^mysql/i
          "SHOW FULL TABLES WHERE table_type = 'BASE TABLE'"
        when /postgresql/i
          %{SELECT tablename
          FROM pg_tables
          WHERE schemaname = ANY (current_schemas(false)) AND table_type = 'BASE TABLE'}
        when /sqlite/i
          %{SELECT name
          FROM sqlite_master
          WHERE type = 'table' AND NOT name = 'sqlite_sequence'}
        when /oracle/i
          "SELECT TABLE_NAME FROM USER_TABLES"
        when /sqlserver/i
          "SELECT table_name FROM information_schema.tables"
        else
          "SHOW FULL TABLES WHERE table_type = 'BASE TABLE'"
        end
      end
    end
  end
end