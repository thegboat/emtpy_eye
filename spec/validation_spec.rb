require 'spec_helper'
require 'bundler/setup'


describe ActiveRecord::Base do
  before(:each) do
    #these classes where added for testing convenience
    BarCore.delete_all
    
    Business.delete_all
    
    @bar = Bar.create(
      :music_genre => "Latin", :best_nights => "Tuesdays", :dress_code => "casual", # bar_core attributes
      :address => "1904 Easy Kaley Orlando, FL 32806", :name => 'Chicos', :phone => '123456789' #business attributes
    )
  end
  
  describe "simple vaidation" do
    it "should be invalid when mti core class validation fails" do
      @bar.music_genre = nil
      @bar.valid?.should eq(false)
    end
  end
  
  describe "inherited validation" do
    it "should be invalid when mti core class validation fails" do
      @bar.name = nil
      @bar.valid?.should eq(false)
    end
  end
  
  describe "inherited database validation" do
    it "should be invalid when mti core class validation fails" do
      new_bar = Bar.new(
        :music_genre => "Latin", :best_nights => "Tuesdays", :dress_code => "casual",
        :address => "1904 Easy Kaley Orlando, FL 32806", :name => 'Chicos', :phone => '123456789'
      )
      new_bar.valid?.should eq(false)
    end
  end
end