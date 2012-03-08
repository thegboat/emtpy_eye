require "active_record"
require "arel"

require "empty_eye/version"

require "empty_eye/view_extension"
require "empty_eye/view_extension_collection"
require "empty_eye/base"
require "empty_eye/shard"
require "empty_eye/schema_dumper"
require "empty_eye/connection_adapter"

module EmptyEye
  # Your code goes here...
end

::ActiveRecord::SchemaDumper.send :include, EmptyEye::SchemaDumper
::ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, EmptyEye::ConnectionAdapter)

