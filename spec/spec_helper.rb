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

ActiveRecord::Migration.create_table :restaurants_core, :force => true do |t|
  t.boolean :kids_area
  t.boolean :wifi
  t.integer :food_genre
  t.datetime :created_at
  t.datetime :updated_at
  t.datetime :deleted_at
end

ActiveRecord::Migration.create_table :bars_core, :force => true do |t|
  t.string :music_genre
  t.string :best_nights
  t.string :dress_code
  t.datetime :created_at
  t.datetime :updated_at
  t.datetime :deleted_at
end

ActiveRecord::Migration.create_table :businesses, :force => true do |t|
  t.integer :biz_id
  t.string :biz_type
  t.string :name
  t.string :address
  t.string :phone
end

#this class is only to make testing easier
class BarCore < ActiveRecord::Base
  self.table_name = 'bars_core'
end

#this class is only to make testing easier
class RestaurantCore < ActiveRecord::Base
  self.table_name = 'restaurants_core'
end

class Business < ActiveRecord::Base
  belongs_to  :biz, :polymorphic => true
end

class Restaurant < ActiveRecord::Base
  mti_class do |t|
    has_one :business, :as => :biz
  end
end

class Bar < ActiveRecord::Base
  mti_class do |t|
    has_one :business, :as => :biz
  end
end
