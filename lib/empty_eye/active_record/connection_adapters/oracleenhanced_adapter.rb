module ActiveRecord
  module ConnectionAdapters
    class OracleEnhancedAdapter
      
      def tables_without_views(name = nil) #:nodoc:
        tables = []
        cursor = execute("SELECT TABLE_NAME FROM USER_TABLES", name)
        while row = cursor.fetch
          tables << row[0]
        end
        tables
      end
      
      def tables(name = nil) #:nodoc:
        tables = tables_without_views(name)
        views = views(name)
        tables | views
      end
      
      def views(name = nil) #:nodoc:
        views = []
        cursor = execute("SELECT VIEW_NAME FROM USER_VIEWS", name)
        while row = cursor.fetch
          views << row[0]
        end
        views
      end
      
    end
  end
end