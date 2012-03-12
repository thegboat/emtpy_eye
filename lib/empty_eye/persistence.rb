module EmptyEye
  module Persistence
    extend ActiveSupport::Concern
    
    #if it is not a mti_class do what you do
    #else let the primary shard do the saving
    def update(attribute_names = @attributes.keys)
      return super unless mti_class?
      shard_wrangler.cascade_save
      1
    end

    #if it is not a mti_class do what you do
    #else let the primary shard do the saving
    #come back and cleanup
    def create
      return super unless mti_class?
      shard_wrangler.cascade_save
      ActiveRecord::IdentityMap.add(self) if ActiveRecord::IdentityMap.enabled?
      @new_record = false
      self.id
    end
    
    #if it is not a mti_class do what you do
    #else let the primary shard do the destruction
    #come back and cleanup
    def destroy
      return super unless mti_class?
      shard_wrangler.destroy
      if ActiveRecord::IdentityMap.enabled? and persisted?
        ActiveRecord::IdentityMap.remove(self)
      end
      @destroyed = true
      freeze
    end
    
    #if it is not a mti_class do what you do
    #else let the primary shard do the deletion
    #come back and cleanup
    def delete
      return super unless mti_class?
      shard_wrangler.class.delete_all(:id => id)
      if ActiveRecord::IdentityMap.enabled? and persisted?
        ActiveRecord::IdentityMap.remove(self)
      end
      @destroyed = true
      freeze
    end
  end
end