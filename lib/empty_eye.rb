require "active_record"
require "arel"

require "empty_eye/version"

require "empty_eye/view_extension"
require "empty_eye/primary_view_extension"
require "empty_eye/view_extension_collection"
require "empty_eye/base"
require "empty_eye/shard"
require "empty_eye/schema_dumper"
require "empty_eye/connection_adapter"
require "empty_eye/persistence"

module EmptyEye
  # Your code goes here...
end

::ActiveRecord::Base.send :include, EmptyEye::Base
::ActiveRecord::Base.send :include, EmptyEye::Persistence
::ActiveRecord::SchemaDumper.send :include, EmptyEye::SchemaDumper
::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, EmptyEye::ConnectionAdapter)

