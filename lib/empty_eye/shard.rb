module EmptyEye
  class Shard < ActiveRecord::Base
    self.abstract_class = true
    
    cattr_accessor :empty_eye_attributes
    
  end
end