module EmptyEye
  module Shard
    
    #module which extends the class that serves as a pointer to the primary table
    #when there is a superclass the shard will inherit from that, else it will inherit from ActiveRecord
    #the primary shard manages all the MTI associated tables for the master class
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    #the instance that owns this primary shard
    #we usually know the master instance ahead of time
    #so we should take care to set this manually
    #we want to avoid the lookup
    def mti_instance
      @mti_instance || mti_master_class.find_by_id(id)
    end
    
    #setter used to associate the primary shard with the master instance
    def mti_instance=(instance)
      @mti_instance = instance
    end
    
    #special save so that the primary shard can keep the master instances tables consistent
    def cascade_save
      #make sure all the shards are there
      cascade_build_associations 
      #this will propagate setters to the appropriate shards
      assign_attributes(mti_safe_attributes)
      self.type = mti_master_class.name if respond_to?("type=")
      #this will autosave shards
      save
      #reset the id and then reload
      mti_instance.id = id
      mti_instance.reload
    end
    
    #reflection on master class; this should never change
    def mti_master_class
      self.class.mti_master_class
    end
  
    private
  
    #make sure the primary shard only tries to update what he should
    def mti_safe_attributes
      mti_instance.attributes.except(
        *self.mti_master_class.extended_with.primary.exclude
      )
    end
  
    #all the instance shards should exist but lets be certain
    #using an autobuild would be more efficient here
    #we shouldnt load associations we dont need to
    def cascade_build_associations
      #go through each extension making sure it is exists and is loaded
      mti_instance.class.extended_with.each do |ext|
        next if ext.primary
        assoc = send(ext.name)
        assoc ||= send("build_#{ext.name}")
        send("#{ext.name}=", assoc)
      end
    end
    
    module ClassMethods
      
      #the shard uses special reflection; overriden here
      def create_reflection(macro, name, options, active_record)
        raise(EmptyEye::NotYetSupported, "through associations are not yet spported") if options[:through]
        klass = options[:through] ? ShardThroughReflection : ShardAssociationReflection
        reflection = klass.new(macro, name, options, active_record)

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      #finder methods should use the master class's type not the shard's
      def type_condition(table = arel_table)
        sti_column = table[inheritance_column.to_sym]

        sti_column.eq(mti_master_class.name)
      end
      
      #overriding find_by_id
      #this is used to retrieve the shard instance for the master instance
      #the type column is removed
      def find_by_id(val)
        query = columns_except_type
        query = query.where(arel_table[:id].eq(val))
        find_by_sql(query.to_sql).first
      end
      
      #the shard uses a special association builder
      def has_one(name, options = {})
        Associations::Builder::ShardHasOne.build(self, name, options)
      end

      #reflection on master class; this should never change
      def mti_master_class
        @mti_master_class
      end

      #the mti_master_class value is set with this setter; should happen only once
      def mti_master_class=(klass)
        @mti_master_class = klass
      end
      
      #overriding to reset the special instance variable
      def reset_column_information
        @columns_except_type = nil
        super
      end
      
      private
      
      #build the arel query once and memoize it
      #this is essentially the select to remove type column
      def columns_except_type
        @columns_except_type ||= begin
          query = arel_table
          (column_names - [inheritance_column]).each do |c|
            query = query.project(arel_table[c.to_sym])
          end
          query
        end
        @columns_except_type.dup
      end
    

    end
  end
end