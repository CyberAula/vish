require 'spec_helper'

describe Excursion do
	before do
		@excursion = Factory(:excursion)
	end
  #pending "add some examples to (or delete) #{__FILE__}"
  it "#ExcursionModel?" do
  	@excursion.class == "Excursion"
  end
  it "#created?"

  it "has name"
  it "can be published"
  it "has an author"
  
end
