require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'with the default delegations' do

  before :all do
    @fields = Contact.column_names - UserDefault.default_rejected_delegate_columns
  end

  before :each do
    @user = UserDefault.new      
  end  

  it 'should declare the association' do
    UserDefault.reflect_on_association(:contact).should_not be_nil
  end

  it 'creates reader methods for the columns' do
    @fields.each do |col|
      @user.should respond_to(col)
    end
  end

  it 'creates writer methods for the columns' do
    @fields.each do |col|
      @user.should respond_to("#{col}=")
    end
  end
  
  # UserDefault.default_rejected_delegate_columns
  # can not be used because it contains :id, :created_at, :updated_at and others
  [:parent_id, :lft ].each do |col|
    it "should NOT respond_to #{name}" do
      @user.should_not respond_to(col)
    end
    
    it "should NOT respond_to #{name}=" do
      @user.should_not respond_to("#{col}=")
    end
  end

  describe "reading from no contact" do
    it "should return nil as firstname" do
      @user.firstname.should be_nil
    end
  
    it "should return nil as lastname" do
      @user.lastname.should be_nil
    end
  end
    

  describe "reading from existing contact" do
    before :each do
      @user.build_contact
      @user.contact.firstname = "John"
      @user.contact.lastname = "Smith"
    end
  
    it "should read firstname" do
      @user.firstname.should == "John"
    end
  
    it "should read lastname" do
      @user.lastname.should == "Smith"
    end
  end

  describe "assigning value to delegators" do
    it "should initialize association" do
      @user.contact.should be_nil
      @user.firstname = "John"
      @user.contact.should_not be_nil
      @user.firstname.should == "John"
    end
    
    it "should NOT initialize association second time" do
      @user.firstname = "John"
      contact_object_id = @user.contact.object_id
      @user.lastname = "Smith"
      @user.contact.object_id.should == contact_object_id
      @user.firstname.should == "John"
    end
    
  end
end