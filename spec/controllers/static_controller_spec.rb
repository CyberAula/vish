require 'spec_helper'

describe StaticController, controllers: true do

	it 'can download static pdf' do 
		get :download_user_manual
		response.content_type.should == 'application/pdf'
		assert_response :success
	end

end