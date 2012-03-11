module EmptyEye
  module Associations
    class ShardHasOneAssociation < ActiveRecord::Associations::HasOneAssociation
      #special association for shard
      #very verbose but will be easier to update later
      #better than monkey patching
      #here we are patching the need to set the polymorphic type for a association
      #the shard is the 'owner' but we want the type to be the master class
      
      def association_scope
        if klass
          @association_scope ||= ShardAssociationScope.new(self).scope
        end
      end
    
      private
    
      def creation_attributes
        attributes = {}

        if reflection.macro.in?([:has_one, :has_many]) && !options[:through]
          attributes[reflection.foreign_key] = owner[reflection.active_record_primary_key]

          if reflection.options[:as]
            attributes[reflection.type] = owner.mti_master_class.base_class.name
          end
        end

        attributes
      end
    
    end
  end
end
  