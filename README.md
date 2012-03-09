# Empty Eye

ActiveRecord based MTI gem powered by database views

#Issues

* Need update all working
* Need delete all working
* Need destroy all working
* No way to change mti class table name
* Know idea if validations are working correctly
* More testing

Create MTI classes by renaming your base table with the core suffix and wrapping your associations in a mti\_class block

Test example from http://techspry.com/ruby_and_rails/multiple-table-inheritance-in-rails-3/ which uses mixins to accomplish MTI:

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

      class Business < ActiveRecord::Base
        belongs_to  :biz, :polymorphic => true
      end

      class Restaurant < ActiveRecord::Base
        mti_class do
          has_one :business, :as => :biz
        end
      end

      class Bar < ActiveRecord::Base
        mti_class(:bars_core) do
          has_one :business, :as => :biz
        end
      end
      
For now the convention is to name the base tables with the suffix core as the view will use the rails table name

In the background the following association options are used :autosave => true, :validate => true, :dependent => :destroy

Changing or adding these options will have no effect but the MTI would be senseless without them

If the class does not descend active record the correct table will be used. Inheriting from STI may work but has not bee n tested.

If you dont want to use the core suffix convention a table can be specified (see Bar class mti implementation)


      1.9.3p0 :005 > Bar
      => Bar(id: integer, music_genre: string, best_nights: string, dress_code: string, created_at: datetime, updated_at: datetime, deleted_at: datetime, name: string, address: string, phone: string)
      
      1.9.3p0 :006 > bar = Bar.create(:music_genre => "Latin", :best_nights => "Tuesdays", :dress_code => "casual", :address => "1904 Easy Kaley Orlando, FL 32806", :name => 'Chicos', :phone => '123456789')
      => #<Bar id: 2, music_genre: "Latin", best_nights: "Tuesdays", dress_code: "casual", created_at: "2012-03-09 18:41:17", updated_at: "2012-03-09 18:41:17", deleted_at: nil, name: "Chicos", address: "1904 Easy Kaley Orlando, FL 32806", phone: "123456789">
      
      1.9.3p0 :008 > bar.phone = '987654321'
       => "987654321" 
      1.9.3p0 :009 > bar.save
       => true
      
      1.9.3p0 :010 > bar.reload
       => #<Bar id: 2, music_genre: "Latin", best_nights: "Tuesdays", dress_code: "casual", created_at: "2012-03-09 18:41:17", updated_at: "2012-03-09 18:41:17", deleted_at: nil, name: "Chicos", address: "1904 Easy Kaley Orlando, FL 32806", phone: "987654321">
       
       1.9.3p0 :011 > bar.destroy
        => #<Bar id: 2, music_genre: "Latin", best_nights: "Tuesdays", dress_code: "casual", created_at: "2012-03-09 18:41:17", updated_at: "2012-03-09 18:41:17", deleted_at: nil, name: "Chicos", address: "1904 Easy Kaley Orlando, FL 32806", phone: "987654321">
      
       1.9.3p0 :013 > Bar.find_by_id(2)
        => nil
      
      
      

