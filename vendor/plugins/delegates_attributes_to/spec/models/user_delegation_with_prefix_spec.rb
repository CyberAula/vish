require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class UserDelegationWithPrefix < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :to => :contact, :prefix => true

  has_one :profile
  delegate_attributes :to => :profile, :prefix => 'account'
end

describe DelegatesAttributesTo, 'delegation with' do

  describe ":prefix => true" do
    before :each do
      @user = UserDelegationWithPrefix.new
    end  

    it "should set reflection autosave option to true" do
      UserDelegationWithPrefix.reflect_on_association(:contact).options[:autosave].should be_true
    end

    describe "dirty on new contact" do

      it "should raise NoMethodError on #firstname" do
        lambda { @user.firstname }.should raise_error(NoMethodError)
      end
    
      it "should return nil as contact firstname" do
        @user.contact_firstname.should be_nil
      end

      it "should raise NoMethodError on #firstname_change" do
        lambda { @user.firstname_change }.should raise_error(NoMethodError)
      end

      it "should return nil as change" do
        @user.contact_firstname_change.should be_nil
      end
    
      it "should raise NoMethodError on #firstname_changed?" do
        lambda { @user.firstname_changed? }.should raise_error(NoMethodError)
      end
    
      it "should not be changed" do
        @user.contact_firstname_changed?.should be_false
      end

      it "should raise NoMethodError on #firstname_was" do
        lambda { @user.firstname_was }.should raise_error(NoMethodError)
      end

      it "should return nil as firstname_was" do
        @user.contact_firstname_was.should be_nil
      end
    
      it "should raise NoMethodError on #firstname_will_change!" do
        lambda { @user.firstname_will_change! }.should raise_error(NoMethodError)
      end
  
      it "should react on will_change!" do
        @user.contact_firstname_will_change!
        @user.contact_firstname_change.should == [nil, nil]
      end
    end
    

    describe "dirty on existing contact" do
      before :each do
        @user.build_contact
        @user.contact.firstname = "John"
        @user.contact.lastname = "Smith"
      end
  
      it "should be changed as user" do
        @user.should be_changed
      end

      it "should be changed as contact" do
        @user.contact.should be_changed
      end
  
      it "should read firstname" do
        @user.contact_firstname.should == "John"
      end
  
      it "should read lastname" do
        @user.contact_lastname.should == "Smith"
      end
    
      it "should return [nil, 'John'] as change" do
        @user.contact_firstname_change.should == [nil, "John"]
      end
    
      it "should not be changed" do
        @user.contact_firstname_changed?.should be_true
      end

      it "should return nil as firstname_was" do
        @user.contact_firstname_was.should be_nil
      end
  
      it "should return nil as lastname" do
        @user.contact_firstname_will_change!
        @user.contact_firstname_change.should == ['John', 'John']
      end
    end
  end
  
  
  describe ":prefix => 'account'" do
    before :each do
      @user = UserDelegationWithPrefix.new
    end  

    describe "dirty on new profile" do

      it "should raise NoMethodError on #about" do
        lambda { @user.about }.should raise_error(NoMethodError)
      end
    
      it "should return nil as contact firstname" do
        @user.account_about.should be_nil
      end

      it "should raise NoMethodError on #firstname_change" do
        lambda { @user.about_change }.should raise_error(NoMethodError)
      end

      it "should return nil as change" do
        @user.account_about_change.should be_nil
      end
    
      it "should raise NoMethodError on #firstname_changed?" do
        lambda { @user.about_changed? }.should raise_error(NoMethodError)
      end
    
      it "should not be changed" do
        @user.account_about_changed?.should be_false
      end

      it "should raise NoMethodError on #about_was" do
        lambda { @user.about_was }.should raise_error(NoMethodError)
      end

      it "should return nil as firstname_was" do
        @user.account_about_was.should be_nil
      end
    
      it "should raise NoMethodError on #firstname_will_change!" do
        lambda { @user.about_will_change! }.should raise_error(NoMethodError)
      end
  
      it "should react on will_change!" do
        @user.account_about_will_change!
        @user.account_about_change.should == [nil, nil]
      end
    end
    

    describe "dirty on existing contact" do
      before :each do
        @user.build_profile
        @user.profile.about = "John"
      end
  
      it "should be changed as user" do
        @user.should be_changed
      end

      it "should be changed as contact" do
        @user.profile.should be_changed
      end
  
      it "should read about" do
        @user.account_about.should == "John"
      end
      
      it "should return [nil, 'John'] as change" do
        @user.account_about_change.should == [nil, "John"]
      end
    
      it "should not be changed" do
        @user.account_about_changed?.should be_true
      end

      it "should return nil as firstname_was" do
        @user.account_about_was.should be_nil
      end
  
      it "should return nil as lastname" do
        @user.account_about_will_change!
        @user.account_about_change.should == ['John', 'John']
      end
    end
  end
end