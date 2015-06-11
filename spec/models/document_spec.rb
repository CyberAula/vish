require 'spec_helper'

describe Document, models:true do

	context "Picture" do

		before do
			@picture = Factory(:picture)
		end

		it 'title?' do
			assert_false @picture.title.blank?
		end

		it 'description?' do
			assert_false @picture.description.blank?
		end

		it 'activity_object?' do 
			assert_false @picture.activity_object.nil?
		end
		
	end

	context "Video" do

		before do
			@video = Factory(:video)
		end

		it 'title?' do
			assert_false @video.title.blank?
		end

		it 'description?' do
			assert_false @video.description.blank?
		end

		it 'activity_object?' do 
			assert_false @video.activity_object.nil?
		end
		
	end

	context "Audio" do

		before do
			@audio = Factory(:audio)
		end

		it 'title?' do
			assert_false @audio.title.blank?
		end

		it 'description?' do
			assert_false @audio.description.blank?
		end

		it 'activity_object?' do 
			assert_false @audio.activity_object.nil?
		end
		
	end
	
end
