require 'spec_helper'

describe "excursions/show.html.erb" do
  before(:each) do
    @excursion = assign(:excursion, stub_model(Excursion))
  end

  it "renders attributes in <p>" do
    render
  end
end
