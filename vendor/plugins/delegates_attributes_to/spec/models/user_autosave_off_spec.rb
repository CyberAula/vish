require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'with dirty delegations' do

  it "should NOT set contact reflection autosave option to true" do
    UserAutosaveOff.reflect_on_association(:contact).options[:autosave].should be_false
  end

  it "should NOT set profile reflection autosave option to true" do
    UserAutosaveOff.reflect_on_association(:profile).options[:autosave].should be_false
  end
  
end