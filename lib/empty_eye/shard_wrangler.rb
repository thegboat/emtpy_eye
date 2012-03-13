module EmptyEye
  module ShardWrangler
    #module which extends the class that serves as a pointer to the primary table
    #when there is a superclass the shard will inherit from that, else it will inherit from ActiveRecord
    #the primary shard manages all the MTI associated tables for the master class
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    #this module method creates a ShardWrangler extended ActiveRecord inherited class
    #the class will wrangle our shards 
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
    
    #the instance that owns this wrangler
    #we usually know the master instance ahead of time
    #so we should take care to set this manually
    #we want to avoid the lookup
    def master_instance
      @master_instance || master_class.find_by_id(id)
    end
    
    #setter used to associate the wrangler with the master instance
    def master_instance=(instance)
      @master_instance = instance
    end
    
    #special save so that the wrangler can keep the master's instance tables consistent
    def cascade_save
      write_attributes
      #this will autosave shards
      save
      #reset the id and then reload
      master_instance.id = id
      master_instance.reload
    end
    
    #reflection on master class; this should never change
    def master_class
      self.class.master_class
    end
    
    def valid?(context = nil)
      context ||= (new_record? ? :create : :update)
      write_attributes
      output = super(context)
      errors.each do |attr, message|
        attr = attr.to_s.partition('.').last if attr.to_s =~ /\./
        master_instance.errors.add(attr, message)
      end
      errors.empty? && output
    end
  
    private
    
    def write_attributes
      #make sure all the shards are there
      cascade_build_associations if master_instance.new_record?
      #this will propagate setters to the appropriate shards
      assign_attributes(mti_safe_attributes)
      self.type = master_class.name if respond_to?("type=")
      self.updated_at = Time.now if respond_to?("updated_at=") and not changed?
      self
    end
    
    def shards
      self.class.shards
    end
  
    #make sure the primary shard only tries to update what he should
    def mti_safe_attributes
      master_instance.attributes.except(
        *self.class.primary_shard.exclude
      )
    end
  
    #all the instance shards should exist
    def cascade_build_associations
      #go through each shard making sure it is exists and is loaded
      shards.each do |shard|
        next if shard.primary
        send(shard.name) || send("build_#{shard.name}")
      end
    end
    
    module ClassMethods
      
      #the wrangler uses special reflection; overriden here
      def create_reflection(macro, name, options, active_record)
        raise(EmptyEye::NotYetSupported, "through associations are not yet spported") if options[:through]
        klass = options[:through] ? ShardThroughReflection : ShardAssociationReflection
        reflection = klass.new(macro, name, options, active_record)

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      #finder methods should use the master class's type not the wrangler's
      def type_condition(table = arel_table)
        sti_column = table[inheritance_column.to_sym]

        sti_column.eq(master_class.name)
      end
      
      #overriding find_by_id
      #this is used to retrieve the wrangler instance for the master instance
      #the type column is removed
      def find_by_id(val)
        query = columns_except_type
        query = query.where(arel_table[:id].eq(val))
        find_by_sql(query.to_sql).first
      end
      
      #the wrangler uses a special association builder
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
      
      #the primary shard
      def primary_shard
        shards.primary
      end
      
      #we know the associations and we know what they can do
      #we will make a mti class accordingly here
      def wrangle_shards(mti_ancestors)
        mti_ancestors.each do |assoc|
          shards.create_with(assoc)
        end
        create_view
        master_class.reset_column_information
      end
      
      #batch deletion when there are conditions
      #kill indiscriminately otherwise
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
    
      #drop the view; dont check if we can, just rescue any errors
      #create the view
      def create_view
        EmptyEye::ViewManager.create_view(compute_view_name, shards.create_view_sql)
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