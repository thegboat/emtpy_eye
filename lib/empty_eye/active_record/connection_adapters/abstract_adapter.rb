module ActiveRecord
  module ConnectionAdapters
    class AbstractAdapter
      
      def ordinary_table_exists?(name)
        tables_without_views.include?(name)
      end
      
      def view_exists?(name)
        views.include?(name)
      end
      
    end
  end
end