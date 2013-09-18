require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class UserHasDelegatedAttrWithDefaultValue < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact, :class_name => 'ContactWithDefault'
  delegate_attribute :firstname, :lastname, :to => :contact
end

class ContactWithDefault < ActiveRecord::Base
  set_table_name 'contacts'
  after_initialize :init_attrs

  private
    def init_attrs
      self.firstname ||= "David"
      self.lastname  ||= "Blaine"
    end

end

describe DelegatesAttributesTo, 'delegated attribute having default value' do

  before :each do
    @user = UserHasDelegatedAttrWithDefaultValue.new
  end  

  describe "without contact" do
    it "should return David when calling firstname" do
      @user.firstname.should  == 'David'
    end
  end
  
  describe "with contact" do
    
    before :each do
      @user.build_contact
    end
    
    it "should return David when calling firstname" do
      @user.firstname.should  == 'David'
    end
  end
end
