require "active_record"
require "arel"

require "empty_eye/version"

require "empty_eye/persistence"
require "empty_eye/relation"
require "empty_eye/errors"
require "empty_eye/view_extension"
require "empty_eye/primary_view_extension"
require "empty_eye/view_extension_collection"
require "empty_eye/shard"
require "empty_eye/associations/builder/shard_has_one"
require "empty_eye/associations/shard_has_one_association"
require "empty_eye/associations/shard_association_scope"
require "empty_eye/shard_association_reflection"

require "empty_eye/active_record/base"
require "empty_eye/active_record/schema_dumper"
require "empty_eye/active_record/connection_adapter"

module EmptyEye
  # Your code goes here...
end

::ActiveRecord::Base.send :include, EmptyEye::Persistence
::ActiveRecord::Base.send :include, EmptyEye::Relation
::ActiveRecord::Associations::Builder::HasOne.valid_options += [:except, :only]
::ActiveRecord::Associations::Builder::BelongsTo.valid_options += [:except, :only]

