require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'with partial dirty delegations' do

  before :each do
    @user = UserPartiallyDirty.new
  end  

  [:lastname, :lastname_change, :lastname_changed?, :lastname_was, :lastname_will_change!].each do |method|
    it "should not respond_to #{method}" do
      @user.should_not respond_to(method)
    end
  end

  describe "changing not tracked attribute" do
    before :each do
      @user.build_contact
      @user.contact.lastname = "Smith"
    end
  
    it "should NOT be changed as user" do
      @user.should_not be_changed
    end
    
    it "should be changed as user.contact" do
      @user.contact.should be_changed
    end
  end
end