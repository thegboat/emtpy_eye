require 'spec_helper'
require 'bundler/setup'


describe ActiveRecord::Base do
  
  before(:each) do
    exec_sql "truncate mechanics_core"
    exec_sql "truncate garages"
    
    @mechanic = Mechanic.new(
      :name => 'Grady',
      :privately_owned => true,
      :max_wait_days => 5,
      :specialty => 'foreign',
      :email => 'gradyg@gmail.com'
    )
    @mechanic.valid?.should eq(true)
  end
  
  describe "simple validation" do
    
    it "should be invalid when mti core class validation fails" do
      @mechanic.name = nil
      @mechanic.valid?.should eq(false)
    end
  end
  
  describe "database validation" do
    it "should save when mti core class database validation succeeds" do
      @mechanic.new_record?.should eq(true)
      @mechanic.save.should eq(true)
      @mechanic.new_record?.should eq(false)
      Mechanic.first.should eq(@mechanic)
    end
    
    it "should be invalid when mti core class validation fails" do
      dupe = @mechanic.clone
      dupe.valid?.should eq(true)
      @mechanic.save
      dupe.valid?.should eq(false)
    end
  end
  
  describe "mti validation" do
    it "should be invalid when inherited validates_presence_of privately_owned validation fails" do
      @mechanic.privately_owned = nil
      @mechanic.valid?.should eq(false)
    end
    
    it "should be invalid when inherited validates_numericality_of max_wait_days validation fails" do
      @mechanic.max_wait_days = nil
      @mechanic.valid?.should eq(false)
    end
    
    it "should be invalid when inherited validates_length_of email validation fails" do
      @mechanic.email = "r@r.cc"
      @mechanic.valid?.should eq(false)
    end
    
    it "should be invalid when inherited validates_format_of email validation fails" do
      @mechanic.email = "bad email"
      @mechanic.valid?.should eq(false)
    end
    
    it "should be invalid when inherited validates_uniqueness_of email validation fails" do
      dupe = @mechanic.clone
      dupe.valid?.should eq(true)
      dupe.name = 'Some other name'
      @mechanic.save
      dupe.valid?.should eq(false)
    end
    
    it "should be invalid when inherited validates_inclusion_of specialty validation fails" do
      @mechanic.specialty = "bad email"
      @mechanic.valid?.should eq(false)
    end
    
    it "should be invalid when inherited validates_exclusion_of specialty validation fails" do
      @mechanic.specialty = "something_crazy"
      @mechanic.valid?.should eq(false)
    end
  end
end