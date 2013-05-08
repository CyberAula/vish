class HelpController < ApplicationController

	def download_user_manual
		send_file "#{Rails.root}/public/vish_user_manual.pdf", :type => 'application/pdf'
	end
end
