require 'spec_helper'

describe "excursions/index.html.erb" do
  before(:each) do
    assign(:excursions, [
      stub_model(Excursion),
      stub_model(Excursion)
    ])
  end

  it "renders a list of excursions" do
    render
  end
end
