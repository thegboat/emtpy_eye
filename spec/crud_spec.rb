require 'spec_helper'
require 'bundler/setup'


describe ActiveRecord::Base do
  before(:each) do
    #these classes where added for testing convenience
    RestaurantCore.delete_all
    BarCore.delete_all
    
    Business.delete_all
    
    @bar = Bar.create(
      :music_genre => "Latin", :best_nights => "Tuesdays", :dress_code => "casual", # bar_core attributes
      :address => "1904 Easy Kaley Orlando, FL 32806", :name => 'Chicos', :phone => '123456789' #business attributes
    )
  end
  
  describe "create" do
    it "should create a mti class correctly" do
      @bar.music_genre.should eq("Latin")
      @bar.best_nights.should eq("Tuesdays")
      @bar.dress_code.should eq("casual")
      @bar.address.should eq("1904 Easy Kaley Orlando, FL 32806")
      @bar.name.should eq("Chicos")
      @bar.phone.should eq("123456789")
    end
    
    it "should create associations correctly" do
      @bar.business.class.should eq(Business)
      
      @bar.business.address.should eq("1904 Easy Kaley Orlando, FL 32806")
      @bar.business.name.should eq("Chicos")
      @bar.business.phone.should eq("123456789")
    end
  end
  
  describe "read" do
    it "should find a mti class correctly" do
      @found_bar = Bar.find_by_id(@bar.id)
      @bar.should eq(@found_bar)
    end
  end
  
  describe "update" do
    it "should update a mti class correctly with update_attributes" do
      @bar.phone.should eq("123456789")
      @bar.update_attributes(:phone => '987654321') #attribute from business
      @bar.reload
      @bar.phone.should eq("987654321")
      @bar.business.phone.should eq("987654321")
    end
    
    it "should update a mti class correctly with assignment" do
      @bar.phone.should eq("123456789")
      @bar.phone = '987654321' #attribute from business
      @bar.save
      @bar.reload
      @bar.phone.should eq("987654321")
      @bar.business.phone.should eq("987654321")
    end
  end
  
  describe "delete" do
    it "should destroy a mti class correctly" do
      @bar.destroy
      @bar.destroyed?.should eq(true)
      Bar.find_by_id(@bar.id).should eq(nil)
    end
    
    it "should delete a mti class correctly" do
      @bar.delete
      @bar.destroyed?.should eq(true)
      Bar.find_by_id(@bar.id).should eq(nil)
    end
  end
end