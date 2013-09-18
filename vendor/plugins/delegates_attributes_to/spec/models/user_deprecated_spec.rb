require File.join(File.dirname(__FILE__), '..', 'spec_helper')

class UserDeprecatedWithPrefix < ActiveRecord::Base
  set_table_name 'users'
end

describe DelegatesAttributesTo, 'deprecated #delegates_attributes_to' do

  it "should call #delegate_attributes with :to => profile" do
    UserDeprecated.should_receive(:delegate_attributes).with(:to => :profile)
    UserDeprecated.delegates_attributes_to :profile
  end
  
  it "should call #delegate_attributes with :to => contact" do
    UserDeprecated.should_receive(:delegate_attributes).with(:to => :contact)
    UserDeprecated.delegates_attributes_to :contact
  end
  
  it "should call #delegate_attributes with :to => profile, :prefix => 'profile'" do
    UserDeprecatedWithPrefix.should_receive(:delegate_attributes).with(:to => :profile, :prefix => 'profile')
    UserDeprecatedWithPrefix.delegate_has_one :profile, :prefix => 'profile'
  end
  
  it "should call #delegate_attributes with :to => contact, :prefix => true" do
    UserDeprecatedWithPrefix.should_receive(:delegate_attributes).with(:to => :contact, :prefix => true)
    UserDeprecatedWithPrefix.delegate_belongs_to :contact, :prefix =>  true
  end
end