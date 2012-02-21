require 'spec_helper'

describe "slides/index.html.erb" do
  before(:each) do
    assign(:slides, [
      stub_model(Slide),
      stub_model(Slide)
    ])
  end

  it "renders a list of slides" do
    render
  end
end
