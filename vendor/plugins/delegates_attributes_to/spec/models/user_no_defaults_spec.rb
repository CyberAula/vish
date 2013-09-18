require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'with no default delegations and one specified delegation' do

  before :each do
    @user = UserNoDefault.new
  end

  it 'should declare the association' do
    UserNoDefault.reflect_on_association(:contact).should_not be_nil
  end

  it 'creates reader methods for fields' do
    [:fullname].each do |col|
      @user.should respond_to(col)
    end
  end

  it 'creates writer methods for fields' do
    [:fullname].each do |col|
      @user.should respond_to("#{col}=")
    end
  end

end
