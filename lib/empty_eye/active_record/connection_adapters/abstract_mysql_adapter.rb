module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter < AbstractAdapter
      
      def tables_without_views(name = nil, database = nil, like = nil) #:nodoc:
        sql = "SHOW FULL TABLES WHERE table_type = 'BASE TABLE'"

        execute_and_free(sql, 'SCHEMA') do |result|
          result.collect { |field| field.first }
        end
      end
      
      def views(name = nil, database = nil, like = nil) #:nodoc:
        sql = "SHOW FULL TABLES WHERE table_type = 'VIEW'"

        execute_and_free(sql, 'SCHEMA') do |result|
          result.collect { |field| field.first }
        end
      end
    end
  end
end