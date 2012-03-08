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

ActiveRecord::Migration.create_table :people_core, :force => true do |t|
  t.string :name
  t.integer :age
  t.integer :cm_tall
  t.datetime :created_at
  t.datetime :updated_at
  t.datetime :deleted_at
end

ActiveRecord::Migration.create_table :poll_responses, :force => true do |t|
  t.integer :person_id
  t.integer :poll_id
  t.integer :answer_id
  t.integer :attribute_name
  t.integer :attribute_value
  t.datetime :created_at
  t.datetime :updated_at
  t.datetime :deleted_at
end

ActiveRecord::Migration.create_table :accounts, :force => true do |t|
  t.string :type
  t.integer :person_id
  t.string :affiliation
  t.string :identification_key
  t.string :username
end

class Account < ActiveRecord::Base
  belongs_to :person
end

class FinanceAccount < Account; end
class SocialAccount < Account; end

class PollResponse < ActiveRecord::Base
  belongs_to :person
end

class Person < EmptyEye::Base
  extend_table(:people_core) do |t|
    t.with_table :accounts
    t.with_table :poll_responses
  end
end
