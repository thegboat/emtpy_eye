module EmptyEye
  module Persistence
    extend ActiveSupport::Concern
    
    def update(attribute_names = @attributes.keys)
      return super unless mti_class?
      primary_shard.cascade_save
      1
    end

    # Creates a record with values matching those of the instance attributes
    # and returns its id.
    def create
      return super unless mti_class?
      primary_shard.cascade_save
      ActiveRecord::IdentityMap.add(self) if ActiveRecord::IdentityMap.enabled?
      @new_record = false
      self.id
    end
    
    def destroy
      return super unless mti_class?
      primary_shard.destroy
      if ActiveRecord::IdentityMap.enabled? and persisted?
        ActiveRecord::IdentityMap.remove(self)
      end
      @destroyed = true
      freeze
    end
    
    def delete
      return super unless mti_class?
      primary_shard.delete
      if ActiveRecord::IdentityMap.enabled? and persisted?
        ActiveRecord::IdentityMap.remove(self)
      end
      @destroyed = true
      freeze
    end
  end
end