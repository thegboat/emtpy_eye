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

def exec_sql(sql)
  ActiveRecord::Base.connection.execute sql
end

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

ActiveRecord::Migration.create_table :garages, :force => true do |t|
  t.boolean :privately_owned
  t.integer :max_wait_days
  t.string :specialty
  t.string :email
  t.integer :mechanic_id
end

ActiveRecord::Migration.create_table :mechanics_core, :force => true do |t|
  t.string :name
end

class Business < ActiveRecord::Base
  belongs_to  :biz, :polymorphic => true
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
end

class EatingVenue < ActiveRecord::Base
  mti_class do |t|
    has_one :mexican_restaurant
  end
end

class Garage < ActiveRecord::Base
  belongs_to :mechanic, :foreign_key => :mechanic_id
  
  validates_presence_of :privately_owned
  validates_numericality_of :max_wait_days
  validates_length_of :email, :minimum => 7
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_uniqueness_of :email
  validates_inclusion_of :specialty, :in => %w{foreign domestic antique something_crazy}
  validates_exclusion_of :specialty, :in => %{ something_crazy }
end

class Mechanic < ActiveRecord::Base
  mti_class :mechanics_core do |t|
    has_one :garage, :foreign_key => :mechanic_id
  end
  
  validates_presence_of :name
  validates_uniqueness_of :name
end




