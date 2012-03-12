module EmptyEye
  module Relation
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def delete_all(conditions = nil)
        return super unless mti_class?
        shard_wrangler.cascade_delete_all(conditions)
      end
      
      def update_all(updates, conditions = nil, options = {})
        return super unless mti_class?
        raise(EmptyEye::InvalidUpdate, "update values for a MTI class must be a hash") unless updates.is_a?(Hash)
        shard_wrangler.cascade_update_all(updates, conditions, options)
      end
    end
  end
end