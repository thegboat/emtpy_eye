module ActiveRecord
  module ConnectionAdapters
    class OciAdapter < AbstractAdapter
      
      def tables(name = nil) #:nodoc:
        tables_without_views(name) | views(name)
      end
      
      def tables_without_views(name = nil) #:nodoc:
        tables = []
        execute("SELECT TABLE_NAME FROM USER_TABLES", name).each { |row| tables << row[0]  }
        tables
      end

      def views(name = nil) #:nodoc:
        views = []
        execute("SELECT VIEW_NAME FROM USER_VIEWS", name).each { |row| views << row[0] }
        views
      end
    end
  end
end