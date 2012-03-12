module ActiveRecord
  module ConnectionAdapters
    class OracleAdapter < AbstractAdapter
      
      def tables(name = nil) #:nodoc:
        tables = []
        execute("SELECT TABLE_NAME FROM USER_TABLES", name).each { |row| tables << row[0]  }
        views = []
        execute("SELECT VIEW_NAME FROM USER_VIEWS", name).each { |row| views << row[0] }
        tables | views
      end

      def tables_without_views(name = nil) #:nodoc:
        tables = []
        execute("SELECT TABLE_NAME FROM USER_TABLES", name).each { |row| tables << row[0]  }
        tables
      end
      
    end
  end
end