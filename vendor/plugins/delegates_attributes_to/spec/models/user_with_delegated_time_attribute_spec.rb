require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class UserDelegatesMultiparameterTimeAttributeWithPrefix < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attribute :edited_at, :to => :contact, :prefix => true
end

describe DelegatesAttributesTo, 'with delegated time attribute' do

  before :each do
    @user = UserWithDelegatedTimeAttribute.new
  end  

  describe "changing not tracked attribute" do
    before :each do
      @user.create_contact(:edited_at => 2.days.ago)
      @user.create_profile(:changed_at => 3.days.ago.to_date)
    end
  
    it "should delegate belongs_to date object attribute" do
      @user.edited_at.should == @user.contact.edited_at
    end
    
    it "should delegate has_one time object attribute" do
      @user.changed_at.should == @user.profile.changed_at
    end
    
  end
  
  # TODO Should it happen?
  # it "should have delegated attribute in attribute list " do
  #   @user.attributes.keys.should include('edited_at')
  # end
    
  describe "belongs_to association / date object" do
  
    before(:each) do
      @attributes = {
        "edited_at(1i)"=>"2009", 
        "edited_at(2i)"=>"11", 
        "edited_at(3i)"=>"4", 
        "edited_at(4i)"=>"10", 
        "edited_at(5i)"=>"43"
      }
      
      @etalon = Date.new(2009,11,4)
    end
    
    it "should assign correct date" do
      @user.attributes = @attributes
      @user.edited_at.should == @etalon
    end

    it "should save correct date" do
      @user.attributes = @attributes
      @user.save
      @user.reload
      @user.edited_at.should == @etalon
    end
  end


  describe "has_one association / time object" do 
    before(:each) do
      @attributes = {
        "changed_at(1i)"=>"2009", 
        "changed_at(2i)"=>"11", 
        "changed_at(3i)"=>"4", 
        "changed_at(4i)"=>"10", 
        "changed_at(5i)"=>"43"
      }
      
      @etalon = Time.mktime(2009,11,4, 10, 43)
    end
    
    it "should assign correct time" do
      @user.attributes = @attributes
      @user.changed_at.should == @etalon
    end

    it "should save correct time" do
      @user.attributes = @attributes
      @user.changed_at.should == @etalon
    end
  end
  
  describe ":prefix => true" do
    before(:each) do
      @user = UserDelegatesMultiparameterTimeAttributeWithPrefix.new
      
      @attributes = {
        "contact_edited_at(1i)"=>"2009", 
        "contact_edited_at(2i)"=>"11", 
        "contact_edited_at(3i)"=>"4", 
      }
      
      @etalon = Date.new(2009,11,4)
    end
    
    it "should assign correct time" do
      @user.attributes = @attributes
      @user.contact_edited_at.should == @etalon
    end

    it "should save correct time" do
      @user.attributes = @attributes
      @user.contact_edited_at.should == @etalon
    end
  end
end