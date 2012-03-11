module EmptyEye
  module Associations
    module Builder
      class ShardHasOne < ActiveRecord::Associations::Builder::HasOne
        
        def build
          reflection = super
          configure_dependency unless options[:through]
          reflection
        end
        
      end
    end
  end
end