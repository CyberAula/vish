require 'spec_helper'

describe "excursions/edit.html.erb" do
  before(:each) do
    @excursion = assign(:excursion, stub_model(Excursion))
  end

  it "renders the edit excursion form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => excursions_path(@excursion), :method => "post" do
    end
  end
end
