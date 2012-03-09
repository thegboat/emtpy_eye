module EmptyEye
  module ShardAssociation
    
    private
    
    def creation_attributes
      attributes = {}
      if reflection.macro.in?([:has_one, :has_many]) && !options[:through]
        attributes[reflection.foreign_key] = owner[reflection.active_record_primary_key]

        if reflection.options[:as]
          attributes[reflection.type] = derive_mti_class_name
        end
      end

      attributes
    end
    
    def derive_mti_class_name
      if owner.class < EmptyEye::Shard
        owner.class.mti_master_class.base_class.name
      else
        owner.class.base_class.name
      end
    end
    
  end
end