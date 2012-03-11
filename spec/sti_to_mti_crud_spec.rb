require 'spec_helper'
require 'bundler/setup'


describe ActiveRecord::Base do
  before(:each) do
    #these classes where added for testing convenience
    Restaurant.delete_all
    Business.delete_all
    
    @restaurant = MexicanRestaurant.create(
      :kids_area => false, :wifi => true, :food_genre => "mexican", # restaurant attributes
      :address => "1904 Easy Kaley Orlando, FL 32806", :name => 'Chicos', :phone => '123456789' #business attributes
    )
  end
  
  describe "create" do
    it "should create a sti to mti class correctly" do
      @restaurant.kids_area.should eq(false)
      @restaurant.wifi.should eq(true)
      @restaurant.food_genre.should eq("mexican")
      @restaurant.address.should eq("1904 Easy Kaley Orlando, FL 32806")
      @restaurant.name.should eq("Chicos")
      @restaurant.phone.should eq("123456789")
    end
    
    it "should create sti to mti associations correctly" do
      @restaurant.business.class.should eq(Business)
      
      @restaurant.business.address.should eq("1904 Easy Kaley Orlando, FL 32806")
      @restaurant.business.name.should eq("Chicos")
      @restaurant.business.phone.should eq("123456789")
    end
  end
  
  describe "read" do
    it "should find a sti to mti class correctly" do
      @found_restaurant = MexicanRestaurant.find_by_id(@restaurant.id)
      @restaurant.should eq(@found_restaurant)
    end
    
    it "should type cast a sti to mti class correctly" do
      @found_restaurant = Restaurant.find_by_id(@restaurant.id)
      @restaurant.class.should eq(@restaurant.class)
      lambda { @found_restaurant.address }.should raise_error(ActiveModel::MissingAttributeError)
      lambda { @found_restaurant.name }.should raise_error(ActiveModel::MissingAttributeError)
      lambda { @found_restaurant.phone }.should raise_error(ActiveModel::MissingAttributeError)
    end
  end
  
  describe "update" do
    it "should update a sti to mti class correctly with update_attributes" do
      @restaurant.phone.should eq("123456789")
      @restaurant.update_attributes(:phone => '987654321') #attribute from business
      @restaurant.reload
      @restaurant.phone.should eq("987654321")
      @restaurant.business.phone.should eq("987654321")
    end
    
    it "should update a sti to mti class correctly with assignment" do
      @restaurant.phone.should eq("123456789")
      @restaurant.phone = '987654321' #attribute from business
      @restaurant.save
      @restaurant.reload
      @restaurant.phone.should eq("987654321")
      @restaurant.business.phone.should eq("987654321")
    end
    
    it "should update a sti to mti class correctly with Class.update" do
      MexicanRestaurant.update(@restaurant.id, :name => 'Betos')
      @restaurant.reload
      @restaurant.name.should eq('Betos')
    end
    
    it "should update a mti class correctly with Class.update_all" do
      rtn = MexicanRestaurant.update_all(:name => 'Betos')
      @restaurant.reload
      rtn.should eq(1)
      @restaurant.name.should eq('Betos')
    end
    
    it "should not update a sti to mti class incorrectly with Class.update_all" do
      rtn = MexicanRestaurant.update_all({:name => 'Betos'}, ["id = ?", @restaurant.id + 1]) #choose the wrong one
      @restaurant.reload
      rtn.should eq(0)
      @restaurant.name.should eq('Chicos')
    end
  end
  
  describe "delete" do
    it "should destroy a sti to mti class correctly" do
      @business = @restaurant.business
      @restaurant.destroy
      @restaurant.destroyed?.should eq(true)
      MexicanRestaurant.find_by_id(@restaurant.id).should eq(nil)
      Business.find_by_id(@business.id).should eq(nil)
    end
    
    it "should destroy_all sti to mti class correctly" do
      MexicanRestaurant.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.destroy_all
      MexicanRestaurant.count.should eq(0)
      Business.count.should eq(0)
    end
    
    it "should not destroy_all sti to mti class incorrectly" do
      MexicanRestaurant.count.should eq(1)
      Business.count.should eq(1)
      MexicanRestaurant.destroy_all(:id => @restaurant.id + 1) #choose the wrong one
      MexicanRestaurant.count.should eq(1)
      Business.count.should eq(1)
    end
    
    it "should delete a sti to mti class correctly" do
      @restaurant.delete
      @restaurant.destroyed?.should eq(true)
      MexicanRestaurant.find_by_id(@restaurant.id).should eq(nil)
    end
    
    it "should delete_all sti to mti class correctly" do
      MexicanRestaurant.count.should eq(1)
      Business.count.should eq(1)
      rtn = MexicanRestaurant.delete_all
      rtn.should eq(1)
      MexicanRestaurant.count.should eq(0)
      Business.count.should eq(0)
    end
    
    it "should not delete_all sti to mti class incorrectly" do
      MexicanRestaurant.count.should eq(1)
      Business.count.should eq(1)
      rtn = MexicanRestaurant.delete_all(:id => @restaurant.id + 1) #choose the wrong one
      rtn.should eq(0)
      MexicanRestaurant.count.should eq(1)
      Business.count.should eq(1)
    end
  end
end