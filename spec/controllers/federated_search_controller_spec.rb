require 'spec_helper'

describe FederatedSearchController, controllers: true do
	it 'empty search' do 
		get :search, q: 'asdfasdfasdf', n: 20
		parsed_json = JSON.parse(response.body)
		parsed_json["total_results"].should be(0) 
	end
	#TODO: To make possible scenarios where we can trust the search engine we need to reindex from here, have to try later
end
