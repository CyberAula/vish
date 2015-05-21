require 'spec_helper'

describe Excursion, models: true do
	before do
		@excursion = Factory(:excursion)
	end
  #pending "add some examples to (or delete) #{__FILE__}"
  it "#ExcursionModel?" do
  	@excursion.class == "Excursion"
  end

  it "has name" do
    !@excursion.title.nil?
  end

  it "is published" do
    !@excursion.draft
  end

  it "has an author" do
    !@excursion.author.nil? && @excursion.author.class == "Actor"
  end
  
end