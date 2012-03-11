module EmptyEye
  module Associations
    module Builder
      class ShardHasOne < ActiveRecord::Associations::Builder::HasOne
        #special association builder for shard
        #very verbose but will be easier to update later
        #better than monkey patching
        #this builder allows the other special shard association-ish classes to be created
        #the ground floor ...
        
        def build
          reflection = super
          configure_dependency unless options[:through]
          reflection
        end
        
      end
    end
  end
end