module EmptyEye
  class ShardAssociationReflection < ActiveRecord::Reflection::AssociationReflection
    #special reflection for shard
    #very verbose but will be easier to update later
    #better than monkey patching
    
    def association_class
      EmptyEye::Associations::ShardHasOneAssociation
      #later we will support all singular associations; for now only has one
      
      # case macro
      # when :belongs_to
      #   if options[:polymorphic]
      #     EmptyEye::Associations::ShardBelongsToPolymorphicAssociation
      #   else
      #     EmptyEye::Associations::ShardBelongsToAssociation
      #   end
      # when :has_one
      #   if options[:through]
      #     EmptyEye::Associations::ShardHasOneThroughAssociation
      #   else
      #     EmptyEye::Associations::ShardHasOneAssociation
      #   end
      # end
    end
    
  end
end