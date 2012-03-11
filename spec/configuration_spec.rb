require 'spec_helper'
require 'bundler/setup'

class SmallMechanic < ActiveRecord::Base
  mti_class :mechanics_core do |t|
    has_one :garage, :foreign_key => :mechanic_id, :except => 'specialty'
  end
end

class TinyMechanic < ActiveRecord::Base
  mti_class :mechanics_core do |t|
    has_one :garage, :foreign_key => :mechanic_id, :only => 'specialty'
  end
end

describe ActiveRecord::Base do
  
  describe "MTI class configuration" do
    it "should exclude columns with except option" do
      mechanic_columns = Mechanic.column_names
      small_mechanic_columns = SmallMechanic.column_names
      delta = mechanic_columns - small_mechanic_columns
      delta.should eq(["specialty"])
    end
  end
  
  describe "MTI class configuration" do
    it "should restrict columns with only option" do
      garage_columns = Garage.column_names
      tiny_mechanic_columns = TinyMechanic.column_names
      intersection = garage_columns & tiny_mechanic_columns
      intersection.should eq(["id", "specialty"])
    end
  end
end