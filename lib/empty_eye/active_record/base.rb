module ActiveRecord
  class Base
    
    class << self
    
      #am i an mti class? easier than making a new class type ... i tried
      def mti_class?
        extended_with.any?
      end
    
      #interface for building mti_class
      #primary table is not necessary if the table named correctly (Bar => bars_core)
      #OR if the class inherits a primary table
      #simply wrap your greasy association in this block
      def mti_class(primary_table = nil)
        self.primary_key = "id"
        raise(EmptyEye::AlreadyExtended, "MTI class method already invoked") if mti_class?
        set_mti_primary_table(primary_table)
        self.table_name = compute_view_name
        extended_with.primary_table(mti_primary_table)
        before_yield = reflect_on_multiple_associations(:has_one)
        yield nil if block_given?
        mti_associations = reflect_on_multiple_associations(:has_one) - before_yield
        extend_mti_class(mti_associations)
        true
      end

      #all data for mti class is stored here
      #when empty it is not so MT-I
      def extended_with
        @extended_with ||= EmptyEye::ViewExtensionCollection.new(self)
      end

      #the class of primary shard
      def mti_primary_shard
        extended_with.primary.shard
      end
      
      #we dont need no freakin' finder
      #the view handles this
      def finder_needs_type_condition?
        !mti_class? and super
      end
      
      private
      
      #we know the associations and we know what they can do
      #we will make a mti class accordingly here
      def extend_mti_class(mti_associations)
        mti_associations.each do |assoc|
          extended_with.association(assoc)
        end
        create_view
        reset_column_information
        inherit_mti_validations
      end
      
      #we need a name for the view
      #need to have a way to set this
      def compute_view_name
        descends_from_active_record? ? compute_table_name : name.underscore.pluralize
      end
      
      #determine the primary table
      #first detrmine if our view name exists; this will need to chage one day
      #if they didnt specify try using the core convention else the superclass
      #if they specified use what the set
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
      
      #we need this when we add new associaton types to extend with
      #we could use the baked in version for now
      def reflect_on_multiple_associations(*assoc_types)
        assoc_types.collect do |assoc_type| 
          reflect_on_all_associations
        end.flatten.uniq
      end

      #determine if what we want to name our view already exists
      def ordinary_table_exists?
        connection.tables_without_views.include?(compute_view_name)
      end
    
      #drop the view; dont check if we can just rescue any errors
      #create the view
      def create_view
        connection.execute("DROP VIEW #{table_name}") rescue nil
        connection.execute(extended_with.create_view_sql)
      end
    
      #we may need to inherit these... not using for now
      def superclass_extensions
        superclass.extended_with.dup.descend(self) unless descends_from_active_record?
      end
      
      #we know how to rebuild the validations from the shards
      #lets call our inherited validation here
      def inherit_mti_validations
        extended_with.validations.each {|args| send(*args)}
      end
    end
    
    private
    
    #a pseudo association method back to instances primary shard
    def mti_primary_shard
      @mti_primary_shard ||= if new_record?
        self.class.mti_primary_shard.new(:mti_instance => self)
      else
        rtn = self.class.mti_primary_shard.find_by_id(id)
        rtn.mti_instance = self
        rtn
      end
    end
    
    #is the instance an instance of mti_class?
    def mti_class?
      self.class.mti_class?
    end
    
  end
end