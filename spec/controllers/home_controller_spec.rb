require 'spec_helper'

describe HomeController, controllers: true, debug:true do

	it 'asking for home as html' do
		get(:index)
		assert_response :success
	end

	it 'asking for home as json' do
		get(:index)
		assert_response :success
	end

end
