require 'spec_helper'

describe "excursions/new.html.erb" do
  before(:each) do
    assign(:excursion, stub_model(Excursion).as_new_record)
  end

  it "renders new excursion editor (not a form)" do
    render
  end
end
