require 'spec_helper'

describe Document, models:true do

	context "Picture" do

		before do
			@picture = Factory(:picture)
		end

		it 'title?' do
			!@picture.title.blank?
		end

		it 'description?' do
			!@picture.description.blank?
		end

		it 'activity_object?' do 
			!@picture.activity_object.nil?
		end
		
	end

	context "Video" do

		before do
			@video = Factory(:video)
		end

		it 'title?' do
			!@video.title.blank?
		end

		it 'description?' do
			!@video.description.blank?
		end

		it 'activity_object?' do 
			!@video.activity_object.nil?
		end
		
	end

	context "Audio" do

		before do
			@audio = Factory(:audio)
		end

		it 'title?' do
			!@audio.title.blank?
		end

		it 'description?' do
			!@audio.description.blank?
		end

		it 'activity_object?' do 
			!@audio.activity_object.nil?
		end
		
	end
	
end
