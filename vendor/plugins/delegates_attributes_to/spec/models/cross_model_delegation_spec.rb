require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'with mutual delegation' do

  before :all do
    UserNoDefault.has_one :profile, :foreign_key => 'user_id'
    UserNoDefault.delegate_attributes :to => :profile
    
    Profile.belongs_to :user, :class_name => 'UserNoDefault', :foreign_key => 'user_id'
    Profile.delegate_attributes :to => :user
  end

  before :each do
    @user = UserDefault.new
    @user.about = "I'm Bob"
    @user.profile.username = "bob"
    @user.save!
  end

  describe "#save" do    
    it "should save and do not raise SystemStackError: stack level too deep" do
      @user = UserDefault.find(@user.id)
      @user.should_not be_changed
      @user.profile.should_not be_changed
      @user.save
    end
  end
end