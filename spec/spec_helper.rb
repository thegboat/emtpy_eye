require 'rubygems'
require 'bundler/setup'

require 'empty_eye'

# RSpec.configure do |config|
#   # some (optional) config here
# end

ActiveRecord::Base.establish_connection(
:adapter => "mysql2",
:database => "empty_eye_test"
)
