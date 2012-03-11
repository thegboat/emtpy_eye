module ActiveRecord
  class Base
    
    class << self
    
      def mti_class?
        extended_with.any?
      end
    
      def mti_class(primary_table = nil)
        self.primary_key = "id"
        raise(EmptyEye::AlreadyExtended, "MTI class method already invoked") if mti_class?
        set_mti_primary_table(primary_table)
        self.table_name = compute_view_name
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
        reset_column_information
        inherit_mti_validations
      end
      
      def mti_associations
        @mti_associations
      end

      def extended_with
        @extended_with ||= EmptyEye::ViewExtensionCollection.new(self)
      end

      def mti_primary_shard
        extended_with.primary.shard
      end
      
      def finder_needs_type_condition?
        !mti_class? and super
      end

      def mti_shard?
        false
      end
      
      private
      
      def compute_view_name
        descends_from_active_record? ? compute_table_name : name.underscore.pluralize
      end
      
      def set_mti_primary_table(primary_table_name)
        @mti_primary_table = if ordinary_table_exists?
          raise(EmptyEye::ViewNameError, "MTI view cannot be created because a table named '#{compute_view_name}' already exists")
        elsif primary_table_name.nil?
          descends_from_active_record? ? "#{compute_table_name}_core" : superclass.table_name
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
        connection.tables_without_views.include?(compute_view_name)
      end
    
      def create_view
        connection.execute("DROP VIEW #{table_name}") rescue nil
        connection.execute(extended_with.create_view_sql)
      end
    
      def superclass_extensions
        superclass.extended_with.dup.descend(self) unless descends_from_active_record?
      end
      
      def inherit_mti_validations
        extended_with.validations.each {|args| send(*args)}
      end
    end
    
    def mti_shard_instance?
      false
    end
    
    def base_class_name
      if mti_shard_instance?
        mti_master_class.base_class.name
      else
        self.class.base_class.name
      end
    end
    
    private
    
    def mti_primary_shard
      @mti_primary_shard ||= if new_record?
        self.class.mti_primary_shard.new(:mti_instance => self)
      else
        rtn = self.class.mti_primary_shard.find_by_id(id)
        rtn.mti_instance = self
        rtn
      end
    end
    
    def mti_class?
      self.class.mti_class?
    end
    
  end
end