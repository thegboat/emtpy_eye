module EmptyEye
  module Shard
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    def mti_instance
      @mti_instance
    end
    
    def mti_instance=(instance)
      @mti_instance = instance
    end
    
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
    
    def mti_shard_instance?
      true
    end
    
    def mti_master_class
      self.class.mti_master_class
    end
  
    private
  
    def mti_safe_attributes
      mti_instance.attributes.except(
        *self.mti_master_class.extended_with.primary.exclude
      )
    end
  
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
      
      def create_reflection(macro, name, options, active_record)
        raise(EmptyEye::NotYetSupported, "through associations are not yet spported") if options[:through]
        klass = options[:through] ? ShardThroughReflection : ShardAssociationReflection
        reflection = klass.new(macro, name, options, active_record)

        self.reflections = self.reflections.merge(name => reflection)
        reflection
      end

      def type_condition(table = arel_table)
        sti_column = table[inheritance_column.to_sym]

        sti_column.eq(mti_master_class.name)
      end
      
      def find_by_id(val)
        query = columns_except_type
        query = query.where(arel_table[:id].eq(val))
        find_by_sql(query.to_sql).first
      end
      
      def has_one(name, options = {})
        Associations::Builder::ShardHasOne.build(self, name, options)
      end

      def mti_master_class
        @mti_master_class
      end

      def mti_master_class=(klass)
        @mti_master_class = klass
      end
      
      def mti_shard?
        true
      end
      
      private
      
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