require 'spec_helper'

describe "slides/edit.html.erb" do
  before(:each) do
    @slide = assign(:slide, stub_model(Slide))
  end

  it "renders the edit slide form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => slides_path(@slide), :method => "post" do
    end
  end
end
