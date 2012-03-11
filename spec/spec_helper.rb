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

ActiveRecord::Migration.create_table :restaurants, :force => true do |t|
  t.string :type
  t.boolean :kids_area
  t.boolean :wifi
  t.integer :eating_venue_id
  t.string :food_genre
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

ActiveRecord::Migration.create_table :eating_venues_core, :force => true do |t|
  t.string :api_venue_id
  t.string :latitude
  t.string :longitude
end

#this class is only to make testing easier
class BarCore < ActiveRecord::Base
  self.table_name = 'bars_core'
end

#this class is only to make testing easier
class EatingVenueCore < ActiveRecord::Base
  self.table_name = 'eating_venues_core'
end

class Business < ActiveRecord::Base
  belongs_to  :biz, :polymorphic => true
  
  validates_uniqueness_of :name
  validates_presence_of :name
end

class Restaurant < ActiveRecord::Base
  belongs_to  :foursquare_venue
end

class MexicanRestaurant < Restaurant
  mti_class do |t|
    has_one :business, :as => :biz
  end
end

class Bar < ActiveRecord::Base
  mti_class do |t|
    has_one :business, :as => :biz
  end
  
  validates_presence_of :music_genre
  validates_uniqueness_of :music_genre
end

class EatingVenue < ActiveRecord::Base
  mti_class do |t|
    has_one :mexican_restaurant
  end
end
