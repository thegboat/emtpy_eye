module ActiveRecord
  class Base
    include EmptyEye::Persistence
    include EmptyEye::Relation
    include EmptyEye::BaseMethods
  end
end