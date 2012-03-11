module EmptyEye
  class ShardAssociationReflection < ActiveRecord::Reflection::AssociationReflection
    
    def association_class
      EmptyEye::Associations::ShardHasOneAssociation
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