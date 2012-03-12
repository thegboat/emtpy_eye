module EmptyEye
  module ShardWrangler
    #module which extends the class that serves as a pointer to the primary table
    #when there is a superclass the shard will inherit from that, else it will inherit from ActiveRecord
    #the primary shard manages all the MTI associated tables for the master class
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    def self.create(master_class, t_name)
      inherit_from = if master_class.base_class == master_class
        ActiveRecord::Base
      else
        master_class.superclass
      end
      
      table_name = if t_name
        t_name
      elsif master_class.descends_from_active_record?
        "#{master_class.name.underscore.pluralize}_core"
      else
        master_class.superclass.table_name
      end
      
      new_class = Class.new(inherit_from)
      new_class.send(:include, ShardWrangler)
      new_class.table_name = table_name
      new_class.master_class = master_class
      EmptyEye.const_set("#{master_class.to_s}Wrangler", new_class)
      new_class
    end
    
    #the instance that owns this primary shard
    #we usually know the master instance ahead of time
    #so we should take care to set this manually
    #we want to avoid the lookup
    def mti_instance
      @mti_instance || master_class.find_by_id(id)
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
      self.type = master_class.name if respond_to?("type=")
      #this will autosave shards
      save
      #reset the id and then reload
      mti_instance.id = id
      mti_instance.reload
    end
    
    #reflection on master class; this should never change
    def master_class
      self.class.master_class
    end
  
    private
  
    #make sure the primary shard only tries to update what he should
    def mti_safe_attributes
      mti_instance.attributes.except(
        *self.class.primary_shard.exclude
      )
    end
  
    #all the instance shards should exist but lets be certain
    #using an autobuild would be more efficient here
    #we shouldnt load associations we dont need to
    def cascade_build_associations
      #go through each extension making sure it is exists and is loaded
      self.class.shards.each do |shard|
        next if shard.primary
        assoc = send(shard.name)
        assoc ||= send("build_#{shard.name}")
        send("#{shard.name}=", assoc)
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

        sti_column.eq(master_class.name)
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
      def master_class
        @master_class
      end

      #the master_class value is set with this setter; should happen only once
      def master_class=(klass)
        @master_class = klass
      end
      
      #overriding to reset the special instance variable
      def reset_column_information
        @columns_except_type = nil
        super
      end
      
      def primary_shard
        shards.primary
      end
      
      #we know the associations and we know what they can do
      #we will make a mti class accordingly here
      def wrangle_shards(mti_ancestors)
        mti_ancestors.each do |assoc|
          shards.create_with(assoc)
        end
        create_view if create_view?
        master_class.reset_column_information
        master_inherits_validations
      end
      
      def cascade_delete_all(conditions)
        mti_clear_identity_map
        affected = 0
        ids = []
        ids = conditions ? select(arel_table[primary_key.to_sym]).where(conditions).collect(&:id) : []
        transaction do
          begin
            batch = ids.pop(10000)
            shards.each do |shard|
              result = if conditions.nil?
                shard.klass.delete_all
              elsif shard.polymorphic_type
                shard.klass.delete_all(shard.foreign_key => batch, shard.polymorphic_type => shard.type_value)
              else
                shard.klass.delete_all(shard.foreign_key => batch)
              end
              affected = [affected, result].max
            end 
          end until ids.to_a.empty?
        end
        affected
      end
      
      def cascade_update_all(updates, conditions, options)
        mti_clear_identity_map
        affected = 0
        stringified_updates = updates.stringify_keys
        ids = conditions ? select(arel_table[primary_key.to_sym]).where(conditions).apply_finder_options(options.slice(:limit, :order)).collect(&:id) : []
        transaction do
          begin
            batch = ids.pop(10000)
            shards.each do |shard|
              cols = shards.delegate_map(shard.name, stringified_updates)
              next if cols.empty?
              result = if conditions.nil?
                shard.klass.update_all(cols)
              elsif shard.polymorphic_type
                shard.klass.update_all(cols, shard.foreign_key => batch, shard.polymorphic_type => shard.type_value)
              else
                shard.klass.update_all(cols, shard.foreign_key => batch)
              end
              affected = [affected, result].max
            end
          end until ids.to_a.empty?
        end
        affected
      end
      
      def shards
        @shards ||= EmptyEye::ShardCollection.new(self)
      end
      
      #we need a name for the view
      #need to have a way to set this
      def compute_view_name
        if master_class.descends_from_active_record?
          master_class.send(:compute_table_name)
        else
          master_class.name.underscore.pluralize
        end
      end
      
      private
      
      def mti_clear_identity_map
        ActiveRecord::IdentityMap.repository[symbolized_base_class].clear if ActiveRecord::IdentityMap.enabled?
      end
      
      #get the schema version
      #we shouldnt recreate views that we donth have to
      def mti_schema_version
        check_for_name_error
        return nil unless connection.table_exists?(compute_view_name)
        return nil unless mti_view_versioned?
        t = Arel::Table.new(compute_view_name)
        q = t.project(t[:mti_schema_version])
        connection.select_value(q.to_sql)
      # rescue
      #   nil
      end

      #determine if what we want to name our view already exists
      def check_for_name_error
        if connection.tables_without_views.include?(compute_view_name)
          raise(EmptyEye::ViewNameError, "MTI view cannot be created because a table named '#{compute_view_name}' already exists")
        end
      end
      
      #we need to create the sql first to determine the schema_version
      #if the current schema version is the same as the old dont recreate the view
      #if it is nil then recreate
      def create_view?
        shards.create_view_sql
        schema_version = mti_schema_version
        schema_version.nil? or schema_version != shards.schema_version
      end
      
      #always recreate
      def mti_view_versioned?
        connection.columns(compute_view_name).any? {|c| c.name == 'mti_schema_version'}
      end
    
      #drop the view; dont check if we can, just rescue any errors
      #create the view
      def create_view
        connection.execute("DROP VIEW #{compute_view_name}") rescue nil
        connection.execute(shards.view_sql)
      end
      
      #we know how to rebuild the validations from the shards
      #lets call our inherited validations here
      def master_inherits_validations
        shards.validations.each {|args| master_class.send(*args)}
        #no need to keep these in memory
        shards.free_validations
      end
      
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