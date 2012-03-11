module EmptyEye
  module Relation
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      
      def delete_all(conditions = nil)
        return super unless mti_class?
        mti_clear_identity_map
        affected = 0
        #if something goes wrong forget it all
        transaction do
          if conditions
            #batch up ids
            ids = select("`#{table_name}`.`#{primary_key}`").where(conditions).collect(&:id)
            #delete all the shards of the mti class matching ids
            mti_batch_perform(ids) do |ext, batch|
              if ext.polymorphic_type
                ext.shard.delete_all(ext.foreign_key => batch, ext.polymorphic_type => ext.type_value)
              else
                ext.shard.delete_all(ext.foreign_key => batch)
              end
            end
          else
            #way simpler if there are no conditions; kill everyone
            extended_with.each do |ext|
              affected = [affected, ext.shard.delete_all].max
            end
          end
        end
        affected
      end
      
      def update_all(updates, conditions = nil, options = {})
        return super unless mti_class?
        raise(EmptyEye::InvalidUpdate, "update values for a MTI class must be a hash") unless updates.is_a?(Hash)
        mti_clear_identity_map
        stringified_updates = updates.stringify_keys
        affected = 0
        transaction do
          if conditions
            #batch up ids
            ids = select(arel_table[primary_key.to_sym]).where(conditions).apply_finder_options(options.slice(:limit, :order)).collect(&:id)
            #update all the shards of the mti class matching ids
            affected = mti_batch_perform(ids) do |ext, batch|
              #delegate map ingests the update hash and regurgitates a smaller hash of the values the shard can handle
              cols = extended_with.delegate_map(ext.name, stringified_updates)
              cols.empty? ? 0 : ext.shard.update_all(cols, ext.foreign_key => batch)
            end
          else
            #way simpler if there are no conditions; change the world!
            extended_with.each do |ext|
              cols = extended_with.delegate_map(ext.name, stringified_updates)
              affected = [(cols.empty? ? 0 : ext.shard.update_all(cols)), affected].max
            end
          end
        end
        affected
      end
      
      private
      
      def mti_clear_identity_map
        ActiveRecord::IdentityMap.repository[symbolized_base_class].clear if ActiveRecord::IdentityMap.enabled?
      end
      
      #lets do 10000 at a time
      def mti_batch_perform(ids)
        affected = 0
        until ids.to_a.empty?
          current_ids =  ids.pop(10000)
          extended_with.each do |ext|
            rtn = yield(ext, current_ids)
            affected = [affected,rtn].max
          end
        end
        affected
      end
    
    end
  end
end