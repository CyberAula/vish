require 'spec_helper'

describe "excursions/edit.html.erb" do
  before(:each) do
    @excursion = assign(:excursion, stub_model(Excursion))
  end

  it "renders the excursion editor (not a form)" do
    render
  end
end
