require 'spec_helper'

describe LreController, controllers: true do
#TODO

	context 'API rest testing' do
		it 'simple' do
			get :search_lre
			assert_response :success
		end

		it 'query for q kik' do
			get :search_lre, :q => 'kik'
			assert_response :success
		end

		it 'good query with limit q kik' do
			get :search_lre, :content => 'kik', :limit => 20
			assert_response :success
		end

		it 'bad query for q kik' do
			get :search_lre, :content => '\#', :cnf => 'a'
			assert_response :success
		end

		it 'try with ids' do
			pending('cant try getJSONForIds what does it do?')
			excursion = Factory(:excursion)
			get :getJSONForIds [excursion.id]
			assert_response :success
		end
	end
end
