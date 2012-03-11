require 'spec_helper'
require 'bundler/setup'


describe ActiveRecord::Base do
  before(:each) do
    exec_sql "truncate eating_venues_core"
    exec_sql "truncate restaurants"
    exec_sql "truncate businesses"
    
    @venue = EatingVenue.create(
      :api_venue_id => 'abcdefg', :latitude => '122.11111', :longitude => '-81,11111', # eating venue attributes
      :kids_area => false, :wifi => true, :food_genre => "mexican", # restaurant attributes
      :address => "1904 Easy Kaley Orlando, FL 32806", :name => 'Chicos', :phone => '123456789' #business attributes
    )
  end
  
  describe "create" do
    it "should create a mti to sti to mti class correctly" do
      @venue.api_venue_id.should eq('abcdefg')
      @venue.latitude.should eq('122.11111')
      @venue.longitude.should eq('-81,11111')
      @venue.kids_area.should eq(false)
      @venue.wifi.should eq(true)
      @venue.food_genre.should eq("mexican")
      @venue.address.should eq("1904 Easy Kaley Orlando, FL 32806")
      @venue.name.should eq("Chicos")
      @venue.phone.should eq("123456789")
    end
    
    it "should create mti to sti to mti associations correctly" do
      @venue.mexican_restaurant.class.should eq(MexicanRestaurant)
      
      @venue.mexican_restaurant.kids_area.should eq(false)
      @venue.mexican_restaurant.wifi.should eq(true)
      @venue.mexican_restaurant.food_genre.should eq("mexican")
      @venue.mexican_restaurant.address.should eq("1904 Easy Kaley Orlando, FL 32806")
      @venue.mexican_restaurant.name.should eq("Chicos")
      @venue.mexican_restaurant.phone.should eq("123456789")
    end
  end
  
  describe "read" do
    it "should find a mti to sti to mti class correctly" do
      @found_venue = EatingVenue.find_by_id(@venue.id)
      @venue.should eq(@found_venue)
    end
  end
  
  describe "update" do
    it "should update a mti to sti to mti class correctly with update_attributes" do
      @venue.phone.should eq("123456789")
      @venue.wifi.should eq(true)
      @venue.update_attributes(:phone => '987654321', :wifi => false) #attribute from business
      @venue.reload
      @venue.phone.should eq("987654321")
      @venue.wifi.should eq(false)
      @venue.mexican_restaurant.phone.should eq("987654321")
      @venue.mexican_restaurant.wifi.should eq(false)
    end
    
    it "should update a mti to sti to mti class correctly with assignment" do
      @venue.phone.should eq("123456789")
      @venue.wifi.should eq(true)
      @venue.wifi = false
      @venue.phone = '987654321' #attribute from business
      @venue.save
      @venue.reload
      @venue.wifi.should eq(false)
      @venue.phone.should eq("987654321")
      @venue.mexican_restaurant.phone.should eq("987654321")
      @venue.mexican_restaurant.wifi.should eq(false)
    end
    
    it "should update a mti to sti to mti class correctly with Class.update" do
      EatingVenue.update(@venue.id, :name => 'Betos', :food_genre => 'Italian')
      @venue.reload
      @venue.name.should eq('Betos')
      @venue.food_genre.should eq('Italian')
    end
    
    it "should update a mti class correctly with Class.update_all" do
      rtn = EatingVenue.update_all(:name => 'Betos', :food_genre => 'Italian')
      @venue.reload
      rtn.should eq(1)
      @venue.name.should eq('Betos')
      @venue.food_genre.should eq('Italian')
    end
    
    it "should not update a mti to sti to mti class incorrectly with Class.update_all" do
      rtn = EatingVenue.update_all({:name => 'Betos', :food_genre => 'Italian'}, ["id = ?", @venue.id + 1]) #choose the wrong one
      @venue.reload
      rtn.should eq(0)
      @venue.name.should eq('Chicos')
      @venue.food_genre.should eq('mexican')
    end
  end
  
  describe "delete" do
    it "should destroy a mti to sti to mti class correctly" do
      @restaurant = @venue.mexican_restaurant
      @venue.destroy
      @venue.destroyed?.should eq(true)
      EatingVenue.find_by_id(@venue.id).should eq(nil)
      @restaurant.business.should eq(nil)
      MexicanRestaurant.find_by_id(@restaurant.id).should eq(nil)
    end
    
    it "should destroy_all mti to sti to mti class correctly" do
      EatingVenue.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.count.should eq(1)
      EatingVenue.destroy_all
      EatingVenue.count.should eq(0)
      Business.count.should eq(0)
      MexicanRestaurant.count.should eq(0)
    end
    
    it "should not destroy_all mti to sti to mti class incorrectly" do
      EatingVenue.count.should eq(1)
      Business.count.should eq(1)
      EatingVenue.destroy_all(:id => @venue.id + 1) #choose the wrong one
      EatingVenue.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.count.should eq(1)
    end
    
    it "should delete a mti to sti to mti class correctly" do
      Business.count.should eq(1)
      MexicanRestaurant.count.should eq(1)
      @venue.delete
      @venue.destroyed?.should eq(true)
      EatingVenue.find_by_id(@venue.id).should eq(nil)
      Business.count.should eq(0)
      MexicanRestaurant.count.should eq(0)
    end
    
    it "should delete_all mti to sti to mti class correctly" do
      EatingVenue.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.count.should eq(1)
      rtn = EatingVenue.delete_all
      rtn.should eq(1)
      EatingVenue.count.should eq(0)
      Business.count.should eq(0)
      MexicanRestaurant.count.should eq(0)
    end
    
    it "should not delete_all mti to sti to mti class incorrectly" do
      EatingVenue.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.count.should eq(1)
      rtn = EatingVenue.delete_all(:id => @venue.id + 1) #choose the wrong one
      rtn.should eq(0)
      EatingVenue.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.count.should eq(1)
    end
  end
end