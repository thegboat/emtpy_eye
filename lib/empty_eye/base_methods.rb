module EmptyEye
  module BaseMethods
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
    
      #am i a mti class? easier than making a new class type ... i tried
      def mti_class?
        !!@shard_wrangler
      end
  
      #interface for building mti_class
      #primary table is not necessary if the table named correctly (Bar => bars_core)
      #OR if the class inherits a primary table
      #simply wrap your greasy associations in this block
      def mti_class(primary_table = nil)
        raise(EmptyEye::AlreadyExtended, "MTI class method already invoked") if mti_class?
        self.primary_key = "id"
        @shard_wrangler = EmptyEye::ShardWrangler.create(self, primary_table)
        self.table_name = @shard_wrangler.compute_view_name
        before_yield = reflect_on_multiple_associations(:has_one)
        yield nil if block_given?
        mti_ancestors = reflect_on_multiple_associations(:has_one) - before_yield
        @shard_wrangler.wrangle_shards(mti_ancestors)
        true
      end
    
      #we need this when we add new associaton types to extend with
      #we could use the baked in version for now
      def reflect_on_multiple_associations(*assoc_types)
        assoc_types.collect do |assoc_type| 
          reflect_on_all_associations(assoc_type)
        end.flatten.uniq
      end

      #we dont need no freakin' type condition
      #the view handles this
      def finder_needs_type_condition?
        !mti_class? and super
      end

      #the class of primary shard
      def shard_wrangler
        @shard_wrangler
      end
    
      def descends_from_active_record?
        if superclass.abstract_class?
          superclass.descends_from_active_record?
        elsif mti_class?
          superclass == ActiveRecord::Base
        else
          superclass == ActiveRecord::Base || !columns_hash.include?(inheritance_column)
        end
      end
    
      private
      
    end
    
    def valid?(context = nil)
      context ||= (new_record? ? :create : :update)
      output = super(context)
      return errors.empty? && output unless mti_class?
      shard_wrangler.valid?(context) && errors.empty? && output
    end
    
    private
    
    #a pseudo association method mapping us back to instances primary shard
    def shard_wrangler
      @shard_wrangler ||= if new_record?
        self.class.shard_wrangler.new(:master_instance => self)
      else
        rtn = self.class.shard_wrangler.find_by_id(id)
        rtn.master_instance = self
        rtn
      end
    end
    
    #is the instance an instance of mti_class?
    def mti_class?
      self.class.mti_class?
    end
  end
end