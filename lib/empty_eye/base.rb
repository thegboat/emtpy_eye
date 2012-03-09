module EmptyEye
  module Base
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
    
      def mti_class?
        extended_with.any?
      end
    
      def mti_class(primary_table = nil)
        self.primary_key = "id"
        raise(EmptyEye::AlreadyExtended, "extend table method already invoked") if mti_class?
        set_mti_primary_table(primary_table)
        self.table_name = compute_table_name 
        extended_with.primary_table(mti_primary_table)
        before_yield = reflect_on_multiple_associations(:has_one)
        yield nil if block_given?
        @mti_associations = reflect_on_multiple_associations(:has_one) - before_yield
        extend_mti_class
        true
      end
      
      def extend_mti_class
        mti_associations.each do |assoc|
          extended_with.association(assoc)
        end
        create_view
      end
      
      def mti_associations
        @mti_associations
      end

      def extended_with
        @extended_with ||= superclass_extensions || ViewExtensionCollection.new(self)
      end

      def primary_shard
        extended_with.primary.shard
      end
      
      def set_mti_primary_table(primary_table_name)
        @mti_primary_table = if primary_table_name.nil?
          descends_from_active_record? ? "#{compute_table_name}_core" : superclass.table_name
        elsif ordinary_table_exists?
          raise(EmptyEye::ViewNameError, "a table named '#{primary_table_name}' already exists")
        else
          primary_table_name
        end
      end
      
      def mti_primary_table
        @mti_primary_table
      end
      
      def reflect_on_multiple_associations(*assoc_types)
        assoc_types.collect do |assoc_type| 
          reflect_on_all_associations
        end.flatten.uniq
      end

      def ordinary_table_exists?
        connection.tables_without_views.include?(compute_table_name)
      end
    
      def create_view
        connection.execute("DROP VIEW #{table_name}") rescue nil
        connection.execute(extended_with.create_view_sql)
      end
    
      def superclass_extensions
        superclass.extended_with.dup unless descends_from_active_record?
      end
    end
    
    private
    
    def primary_shard
      @primary_shard ||= if new_record?
        self.class.primary_shard.new(:mti_instance => self)
      else
        self.class.primary_shard.find_by_id(id)
      end
    end
    
    def table_extended_with
      self.class.extended_with
    end
    
    def mti_class?
      self.class.mti_class?
    end
    
  end
end