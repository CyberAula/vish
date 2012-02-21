require 'spec_helper'

describe "slides/show.html.erb" do
  before(:each) do
    @slide = assign(:slide, stub_model(Slide))
  end

  it "renders attributes in <p>" do
    render
  end
end
