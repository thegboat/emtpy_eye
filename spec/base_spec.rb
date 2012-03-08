require 'spec_helper'
require 'bundler/setup'


describe ActiveRecord::Base do
  before(:each) do
    Person.delete_all
    Account.delete_all
    PollResponse.delete_all
    
    person = Person.create(:name => 'Grady Griffin', :age => 38, :cm_tall => 188)
    person.create_account(:affiliation => 'Twitter', :identification_key => 'thegboat', :username => 'thegboat')
    person.poll_responses.create(:attribute_name => 'political_party', :attribute_value => 'Democrat')
  end
  
  describe "associations" do
    it "should work as usual" do
      person = Person.first
      person.social_account.should eq(SocialAccount.first)
      person.finance_account.should eq(FinanceAccount.first)
      person.accounts.count.should eq(2)
      person.poll_responses.count.should eq(1)
    end
  end
end