module EmptyEye
  module Persistence
    extend ActiveSupport::Concern
    
    def update(attribute_names = @attributes.keys)
      return super unless mti_class?
      primary_record = primary_shard.find_by_id(id)
      primary_record.cascade_save(self)
      1
    end

    # Creates a record with values matching those of the instance attributes
    # and returns its id.
    def create
      return super unless mti_class?
      primary_record = primary_shard.new
      primary_record.cascade_save(self)
      ActiveRecord::IdentityMap.add(self) if ActiveRecord::IdentityMap.enabled?
      @new_record = false
      self.id
    end
  end
end