require 'spec_helper'

describe "excursions/new.html.erb" do
  before(:each) do
    assign(:excursion, stub_model(Excursion).as_new_record)
  end

  it "renders new excursion form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => excursions_path, :method => "post" do
    end
  end
end
