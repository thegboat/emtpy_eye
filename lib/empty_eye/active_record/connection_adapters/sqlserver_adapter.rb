module ActiveRecord
  module ConnectionAdapters
    class SQLServerAdapter < AbstractAdapter
      
      # Get all of the non-view tables from the currently connected schema
      def tables_without_views(name = nil)
        # this is untested
        select_values("SELECT table_name FROM information_schema.tables", name)
      end
      
      # Returns all the view names from the currently connected schema.
      def views(name = nil)
        select_values("SELECT table_name FROM information_schema.views", name)
      end
      
      def tables(name = nil)
        tables_without_views(name) | views(name)
      end
    end
  end
end